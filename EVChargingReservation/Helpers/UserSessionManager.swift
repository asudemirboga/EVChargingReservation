//
//  UserSessionManager.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 7.05.2025.
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

final class UserSessionManager: ObservableObject {
    static let shared = UserSessionManager()
    
    @Published var shouldCompleteManualCarInfo: Bool = false
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    @Published var batteryLevel: Double?
    @Published var avgConsumptionRate: Double?
    @Published var batteryCapacity: Double?
    @Published var carModel: String?
    
    private let db = Firestore.firestore()
    private var userEVInfoListener: ListenerRegistration?
    
    private init() {}
    
    func startListeningUserEVInfo() {
        guard let user = Auth.auth().currentUser else { return }
        
        userEVInfoListener = db.collection("users").document(user.uid)
            .addSnapshotListener { docSnapshot, error in
                if let data = docSnapshot?.data() {
                    self.batteryLevel = data["batteryLevel"] as? Double
                    self.avgConsumptionRate = data["avgConsumptionRate"] as? Double
                    self.batteryCapacity = data["batteryCapacity"] as? Double
                    self.carModel = data["carModel"] as? String
                    
                    
                } else {
                    print("[UserSession] Live listener error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
    }
    
    func stopListeningUserEVInfo() {
        userEVInfoListener?.remove()
        userEVInfoListener = nil
    }
    
    func logIn(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if let authErrorCode = AuthErrorCode(rawValue: error.code) {
                    let message: String
                    switch authErrorCode {
                    case .wrongPassword, .invalidEmail:
                        message = "Email or password is incorrect."
                    case .userNotFound:
                        message = "No account found for this email. Please sign up."
                    default:
                        message = "An unexpected error occurred. Please try again."
                    }
                    completion(message)
                } else {
                    completion("An unexpected error occurred. Please try again.")
                }
            } else if let user = result?.user {

                self.createUserIfNeeded(uid: user.uid, email: user.email ?? "") {

                    self.checkIfManualCarInfoNeeded(uid: user.uid) { needsManualInfo in
                        DispatchQueue.main.async {
                            self.shouldCompleteManualCarInfo = needsManualInfo
                            self.isLoggedIn = true
                            completion(nil)
                        }
                    }
                }
            }
        }
    }

    
    func logout() {
        stopListeningUserEVInfo()
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("[SessionManager] Firebase logout failed: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String, completion: @escaping (String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error as NSError? {
                if let authErrorCode = AuthErrorCode(rawValue: error.code) {
                    switch authErrorCode {
                    case .userNotFound:
                        completion("No account found for this email.")
                    case .invalidEmail:
                        completion("Please enter a valid email.")
                    default:
                        completion("An unexpected error occurred. Please try again.")
                    }
                } else {
                    completion("An unexpected error occurred. Please try again.")
                }
            } else {
                completion("Password reset email sent! Please check your inbox.")
            }
        }
    }


    
    private func createUserIfNeeded(
        uid: String,
        email: String,
        completion: @escaping () -> Void
    ) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let error = error {
                print("[UserCheck] Failed to check user profile: \(error.localizedDescription)")
                completion()
                return
            }

            if let document = document, document.exists {
                completion()
                return
            }
            
            let defaultData: [String: Any] = [
                "email": email,
                "carModel": "",
                "avgConsumptionRate": 0.0,
                "batteryCapacity": 0
            ]
            
            userRef.setData(defaultData) { error in
                if let error = error {
                    print("[UserCheck] Firestore user create error: \(error.localizedDescription)")
                }

                completion()
            }
        }
    }
    
    private func checkIfManualCarInfoNeeded(uid: String, completion: @escaping (Bool) -> Void) {
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { document, error in
            guard let data = document?.data(), error == nil else {
                completion(true)
                return
            }

            let carModel = data["carModel"] as? String ?? ""
            let avgConsumptionRate = data["avgConsumptionRate"] as? Double ?? 0
            let batteryCapacity = data["batteryCapacity"] as? Double ?? 0

            let needsManualInfo =
                carModel.isEmpty ||
                avgConsumptionRate <= 0 ||
                batteryCapacity <= 0

            completion(needsManualInfo)
        }
    }
    
    
    func updateManualCarInfo(car: CarModel, batteryLevel: Float, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        
        let updateData: [String: Any] = [
            "carModel": car.name,
            "avgConsumptionRate": car.avgConsumptionRate,
            "batteryCapacity": car.batteryCapacity,
            "batteryLevel": batteryLevel
        ]
        
        userRef.updateData(updateData, completion: completion)
    }
    
    func fetchUserEVInfo() {
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("users").document(user.uid).getDocument { doc, error in
            if let data = doc?.data() {
                self.batteryLevel = data["batteryLevel"] as? Double
                self.avgConsumptionRate = data["avgConsumptionRate"] as? Double
                self.batteryCapacity = data["batteryCapacity"] as? Double
                self.carModel = data["carModel"] as? String
            } else {
                print("[UserSession] Failed to load EV info: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

extension UserSessionManager {
    func fetchNearbyStations(from userLocation: CLLocationCoordinate2D, radiusInMeters: Double = 5000, completion: @escaping ([ChargingStation]) -> Void) {
        let db = Firestore.firestore()
        db.collection("stations").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching stations: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            let nearbyStations = documents.compactMap { doc -> ChargingStation? in
                let data = doc.data()

                guard let name = data["station_id"] as? String,
                      let lat = data["latitude"] as? CLLocationDegrees,
                      let lng = data["longitude"] as? CLLocationDegrees,
                      let postcode = data["postcode"] as? Int,
                      let area = data["area"] as? String,
                      let totalPlugs = data["total_plugs"] as? Int else {
                    return nil
                }

                let stationLocation = CLLocation(latitude: lat, longitude: lng)
                let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                let distance = userLoc.distance(from: stationLocation)

                if distance <= radiusInMeters {
                    return ChargingStation(
                        stationID: name,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                        postcode: postcode,
                        area: area,
                        totalPlugs: totalPlugs
                    )
                } else {
                    return nil
                }
            }

            completion(nearbyStations)
        }
    }
    
    func fetchStationDetail(stationID: String, completion: @escaping (ChargingStation?) -> Void) {
        let docRef = Firestore.firestore().collection("stations").document(stationID)
        docRef.getDocument { document, error in
            if let error = error {
                print("Firestore error: \(error.localizedDescription)")
                   }

            if let document = document, document.exists {
                let data = document.data() ?? [:]

                guard let lat = data["latitude"] as? CLLocationDegrees,
                      let lng = data["longitude"] as? CLLocationDegrees,
                      let postcode = data["postcode"] as? Int,
                      let area = data["area"] as? String,
                      let totalPlugs = data["total_plugs"] as? Int else {
                    print("Missing fields in document for stationID: \(stationID)")
                    completion(nil)
                    return
                }

                let station = ChargingStation(
                    stationID: stationID,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    postcode: postcode,
                    area: area,
                    totalPlugs: totalPlugs
                )

                completion(station)
            } else {
                print("No Firestore document found for stationID: \(stationID)")
                completion(nil)
            }
        }
    }
    
    func saveBatteryLevel(_ level: Float, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }

        let userRef = db.collection("users").document(user.uid)
        userRef.updateData(["batteryLevel": level]) { error in
            if let error = error {
                print("Failed to update battery level: \(error.localizedDescription)")
            } else {
                self.batteryLevel = Double(level) // update local state immediately
            }
            completion(error)
        }
    }
    
    func fetchStationAvailability(stationID: String, timestamp: Date, completion: @escaping (Double?) -> Void) {
        let db = Firestore.firestore()
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        let timestampString = formatter.string(from: timestamp)
        
        db.collection("stations")
            .document(stationID)
            .collection("status")
            .document(timestampString)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Failed to fetch station availability: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let data = snapshot?.data() else {
                    print("No availability data found for \(stationID) at \(timestampString)")
                    completion(nil)
                    return
                }

                
                let available = data["available"] as? Double
                completion(available)
            }
    }



}
