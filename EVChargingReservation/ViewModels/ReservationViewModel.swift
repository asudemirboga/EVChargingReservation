//
//  ReservationViewModel.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 18.05.2025.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReservationViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var reservationSuccess: Bool = false
    @Published var reservationError: String?
    @Published var userReservations: [Reservation] = []

    private let db = Firestore.firestore()
    
    private func checkForOverlappingReservations(
        userID: String,
        newStartTime: Date,
        newBlockCount: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let newEndTime = Calendar.current.date(byAdding: .minute, value: newBlockCount * 15, to: newStartTime)!

        db.collection("reservations")
            .whereField("userID", isEqualTo: userID)
            .whereField("status", isEqualTo: "active")
            .whereField("startTime", isLessThan: newEndTime)  // fetch candidates that may overlap
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to check overlapping reservations: \(error.localizedDescription)")
                    completion(true)
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(true)
                    return
                }

                let hasOverlap = documents.contains { doc in
                    let existingStart = (doc["startTime"] as? Timestamp)?.dateValue() ?? Date.distantPast
                    let existingBlockCount = doc["blockCount"] as? Int ?? 1
                    let existingEnd = Calendar.current.date(byAdding: .minute, value: existingBlockCount * 15, to: existingStart)!

                    // OVERLAP CONDITION
                    return newStartTime < existingEnd && newEndTime > existingStart
                }

                completion(hasOverlap)
            }
    }
    

    func createReservation(
        station: ChargingStation,
        startTime: Date,
        blockCount: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
            reservationError = "User not logged in"
            completion(false)
            return
        }

        checkForOverlappingReservations(userID: user.uid, newStartTime: startTime, newBlockCount: blockCount) { hasConflict in
            if hasConflict {
                self.reservationError = "You already have a reservation that overlaps with this time."
                self.reservationSuccess = false
                completion(false)
                return
            }

            // Continue availability check
            let totalPlugs = station.totalPlugs
            guard totalPlugs > 0 else {
                self.reservationError = "Invalid station plug count"
                completion(false)
                return
            }
            var allBlocksReservable = true
            let timeBlocks: [Date] = (0..<blockCount).map {
                Calendar.current.date(byAdding: .minute, value: $0 * 15, to: startTime)!
            }

            self.isLoading = true
            let group = DispatchGroup()

            for blockStart in timeBlocks {
                group.enter()

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                formatter.timeZone = TimeZone(identifier: "Europe/Paris")

                let timestamp = formatter.string(from: blockStart)

                SlotFitScoreManager.predictAvailability(
                    stationID: station.stationID,
                    timestamp: timestamp
                ) { prediction in

                    guard let predictedRate = prediction else {
                        allBlocksReservable = false
                        group.leave()
                        return
                    }

                    ReservationChecker.getReservationCount(
                        for: station.stationID,
                        at: blockStart
                    ) { count in

                        guard let count = count else {
                            allBlocksReservable = false
                            group.leave()
                            return
                        }

                        let predictedAvailable = predictedRate * Double(totalPlugs)
                        let adjusted = predictedAvailable - Double(count)
                        let adjustedRate = adjusted / Double(totalPlugs)

                        if adjustedRate <= 0.5 {
                            allBlocksReservable = false
                        }

                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                if allBlocksReservable {
                    self.saveReservation(
                        userID: user.uid,
                        station: station,
                        startTime: startTime,
                        blockCount: blockCount,
                        completion: completion
                    )
                } else {
                    self.isLoading = false
                    self.reservationError = "This station is unavailable for reservations due to availability being lower than the 50% limit."
                    completion(false)
                }
            }
        }
    }



    private func saveReservation(userID: String, station: ChargingStation, startTime: Date, blockCount: Int, completion: @escaping (Bool) -> Void) {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let parisTimeString = formatter.string(from: startTime)

        let reservationData: [String: Any] = [
            "userID": userID,
            "stationID": station.stationID,
            "stationLatitude": station.coordinate.latitude,
            "stationLongitude": station.coordinate.longitude,
            "startTime": startTime,
            "startTimeFormatted": parisTimeString,
            "blockCount": blockCount,
            "status": "active",
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("reservations").addDocument(data: reservationData) { error in
            self.isLoading = false
            self.reservationSuccess = (error == nil)
            self.reservationError = error?.localizedDescription
            completion(error == nil)
        }
    }


    

    func fetchUserReservations() {
        guard let user = Auth.auth().currentUser else { return }

        db.collection("reservations")
            .whereField("userID", isEqualTo: user.uid)
            .whereField("status", isEqualTo: "active")
            .order(by: "startTime", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch reservations: \(error.localizedDescription)")
                    return
                }

                if let docs = snapshot?.documents {
                    self.userReservations = docs.compactMap { doc in
                        try? doc.data(as: Reservation.self)
                    }
                }
            }
    }
    
    func cancelReservation(_ reservation: Reservation, completion: @escaping (Bool) -> Void) {
        guard let id = reservation.id else {
            completion(false)
            return
        }

        db.collection("reservations").document(id).updateData([
            "status": "cancelled"
        ]) { error in
            if let error = error {
                print("Failed to cancel reservation: \(error.localizedDescription)")
                completion(false)
            } else {
                self.fetchUserReservations() // refresh list
                completion(true)
            }
        }
    }



}
