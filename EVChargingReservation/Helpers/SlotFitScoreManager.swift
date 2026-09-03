//
//  SlotFitScoreManager.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 25.04.2025.
//

import CoreLocation
import FirebaseFirestore

struct SlotFitScoreManager {
    
    static func getETA(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (Int?) -> Void){
        
        guard let apiKey = SecretsManager.getAPIKey(for: "GoogleMapsPlatformAPIKey"),
              !apiKey.isEmpty else {
            print("Google Maps API key is not configured")
            completion(nil)
            return
        }
        let urlStr = """
        https://maps.googleapis.com/maps/api/directions/json?origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=driving&departure_time=now&key=\(apiKey)
        """
        
        guard let url = URL(string: urlStr) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url){ data,_,error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                  let routes = json["routes"] as? [[String:Any]],
                  let firstRoute = routes.first,
                  let legs = firstRoute["legs"] as? [[String:Any]],
                  let firstLeg = legs.first,
                  let duration = firstLeg["duration"] as? [String:Any],
                  let value = duration["value"] as? Int
            else {
                completion(nil)
                return
            }
            let etaMinutes = Int(value / 60)
            completion(etaMinutes)
        }.resume()
    }
    
    static func predictAvailability(
           stationID: String,
           timestamp: String,
           completion: @escaping (Double?) -> Void
       ) {
           let formatter = DateFormatter()
           formatter.dateFormat = "yyyy-MM-dd HH:mm"
           formatter.timeZone = TimeZone(identifier: "Europe/Paris")
           guard let date = formatter.date(from: timestamp) else {
               completion(nil)
               return
           }

           var calendar = Calendar(identifier: .gregorian)
           calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
           
           let hour = calendar.component(.hour, from: date)
           let minute = calendar.component(.minute, from: date)
           let tod = (hour * 4) + (minute / 15)
           let dow = calendar.component(.weekday, from: date)

           // Fetch Firestore info for station features
           let db = Firestore.firestore()
           db.collection("stations").document(stationID).collection("status").document(timestamp).getDocument { doc, error in
               guard let data = doc?.data(), error == nil else {
                   print("Firestore fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                   completion(nil)
                   return
               }

               let payload: [String: Any] = [
                   "Station": stationID,
                   "tod": "\(tod)",
                   "dow": "\(dow)",
                   "station_15min_avg_available": data["station_15min_avg_available"] ?? 0,
                   "station_dow_avg_available": data["station_dow_avg_available"] ?? 0,
                   "area_avg_available": data["area_avg_available"] ?? 0,
                   "station_smoothed_trend": data["station_smoothed_trend"] ?? 0,
                   "previous_available": data["previous_available"] ?? 0,
                   "previous_charging": data["previous_charging"] ?? 0
               ]

               guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                   print("JSON serialization failed")
                   completion(nil)
                   return
               }

               guard let host = SecretsManager.getAPIKey(for: "MLBackendHost"), !host.isEmpty else {
                   print("ML backend host is not configured")
                   completion(nil)
                   return
               }
               let port: UInt32 = 6000
               var inputStream: InputStream?
               var outputStream: OutputStream?

               Stream.getStreamsToHost(withName: host, port: Int(port), inputStream: &inputStream, outputStream: &outputStream)

               guard let input = inputStream, let output = outputStream else {
                   print("Stream creation failed")
                   completion(nil)
                   return
               }

               input.open()
               output.open()

               jsonData.withUnsafeBytes { buffer in
                   if let base = buffer.baseAddress {
                       _ = output.write(base.assumingMemoryBound(to: UInt8.self), maxLength: buffer.count)
                   }
               }

               DispatchQueue.global().async {
                   let bufferSize = 4096
                   var buffer = [UInt8](repeating: 0, count: bufferSize)
                   let bytesRead = input.read(&buffer, maxLength: bufferSize)

                   if bytesRead > 0 {
                       let responseData = Data(bytes: buffer, count: bytesRead)

                       if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                          let predicted = json["prediction"] as? Double {
                           DispatchQueue.main.async {
                               completion(predicted)
                           }
                       } else {
                           print("Failed to parse response")
                           DispatchQueue.main.async {
                               completion(nil)
                           }
                       }
                   } else {
                       print("No data received")
                       DispatchQueue.main.async {
                           completion(nil)
                       }
                   }

                   input.close()
                   output.close()
               }
           }
       }
    
    static func ceilToNext15Minutes(from date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 15
        let adjustment = remainder == 0 ? 0 : (15 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }
    
    static func floorToPrevious15Minutes(from date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let adjustment = -(minute % 15)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }

    
    
}
