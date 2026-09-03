//
//  NavigationHelper.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 1.06.2025.
//

import Foundation
import CoreLocation
import GoogleMaps

class NavigationHelper {
    static func fetchRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (GMSPath?) -> Void) {
        
        guard let apiKey = SecretsManager.getAPIKey(for: "GoogleMapsPlatformAPIKey"),
              !apiKey.isEmpty else {
            print("Google Maps API key is not configured")
            completion(nil)
            return
        }
        
        let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&mode=driving&key=\(apiKey)"

        guard let url = URL(string: urlStr) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let routes = json["routes"] as? [[String: Any]],
                  let route = routes.first,
                  let overviewPolyline = route["overview_polyline"] as? [String: Any],
                  let points = overviewPolyline["points"] as? String,
                  let path = GMSPath(fromEncodedPath: points)
            else {
                completion(nil)
                return
            }

            completion(path)
        }.resume()
    }
}

