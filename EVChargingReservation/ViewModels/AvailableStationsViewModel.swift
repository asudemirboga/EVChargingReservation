//
//  AvailableStationsViewModel.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 14.05.2025.
//
import SwiftUI
import CoreLocation
import FirebaseFirestore

class AvailableStationsViewModel: ObservableObject {
    @Published var scoredStations: [ScoredStation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?


    var allNearbyStations: [ChargingStation] = []
    private var currentBatchIndex = 0
    private let batchSize = 10
    private var seenStationTimePairs = Set<String>()
    private var sortedByETAStations: [(station: ChargingStation, etaMinutes: Int)] = []

    private(set) var lastFetchParams: (Double, CLLocationCoordinate2D, Date)? = nil

    func fetchInitialStations(
        batteryThreshold: Double,
        userLocation: CLLocationCoordinate2D,
        baseDate: Date,
        session: UserSessionManager = .shared
    ) {
        self.lastFetchParams = (batteryThreshold, userLocation, baseDate)
        self.currentBatchIndex = 0
        self.scoredStations = []
        self.seenStationTimePairs.removeAll()

        guard let batteryLevel = session.batteryLevel,
              let batteryCapacity = session.batteryCapacity,
              let consumptionRate = session.avgConsumptionRate,
              batteryCapacity > 0,
              consumptionRate > 0 else {
            self.errorMessage = "Missing or invalid EV data"
            return
        }

        let usablePercent = max(0, batteryLevel - batteryThreshold)
        let rangeKm = (usablePercent / 100.0) * batteryCapacity / consumptionRate
        let rangeMeters = rangeKm * 1000

        isLoading = true

        session.fetchNearbyStations(from: userLocation, radiusInMeters: rangeMeters) { stations in
            self.allNearbyStations = stations.sorted {
                let stationLocation = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                return stationLocation.distance(from: userCLLocation) <
                       CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: userCLLocation)
            }
            self.prepareStationsSortedByETA(baseDate: baseDate, userLocation: userLocation) {
                self.loadNextBatch(baseDate: baseDate, userLocation: userLocation)
            }
        }
    }
    
    func prepareStationsSortedByETA(
        baseDate: Date,
        userLocation: CLLocationCoordinate2D,
        completion: @escaping () -> Void
    ) {
        let group = DispatchGroup()
        var etaResults: [(station: ChargingStation, etaMinutes: Int)] = []

        for station in allNearbyStations {
            group.enter()
            SlotFitScoreManager.getETA(from: userLocation, to: station.coordinate) { etaMinutes in
                if let eta = etaMinutes {
                    DispatchQueue.main.async {
                        etaResults.append((station, eta))
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.sortedByETAStations = etaResults.sorted { $0.etaMinutes < $1.etaMinutes }
            completion()
        }
    }


    func loadNextBatch(
        baseDate: Date,
        userLocation: CLLocationCoordinate2D
    ) {
        guard currentBatchIndex < sortedByETAStations.count else { return }
        
        isLoading = true
        let nextBatch = sortedByETAStations.dropFirst(currentBatchIndex).prefix(batchSize)
        let group = DispatchGroup()
        var newScored: [ScoredStation] = []

        for entry in nextBatch {
            let station = entry.station
            let eta = entry.etaMinutes
            
            group.enter()
            
            let rawETA = Calendar.current.date(byAdding: .minute, value: eta, to: baseDate)!
            let etaDate = SlotFitScoreManager.ceilToNext15Minutes(from: rawETA)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.timeZone = TimeZone(identifier: "Europe/Paris")
            let timestamp = formatter.string(from: etaDate)

            let key = "\(station.stationID)_\(timestamp)"
            if self.seenStationTimePairs.contains(key) {
                group.leave()
                continue
            }
            self.seenStationTimePairs.insert(key)


            SlotFitScoreManager.predictAvailability(stationID: station.stationID, timestamp: timestamp) { prediction in
                if let predicted = prediction {
                    ReservationChecker.getReservationCount(for: station.stationID, at: etaDate) { reservedCount in

                        guard let reservedCount = reservedCount else {
                            group.leave()
                            return
                        }

                        let totalPlugs = Double(station.totalPlugs)
                        let predictedPlugs = predicted * totalPlugs
                        let adjusted = predictedPlugs - Double(reservedCount)
                        let finalScore = max(0, adjusted / totalPlugs)


                        let scored = ScoredStation(
                            station: station,
                            etaMinutes: eta,
                            fitScore: finalScore,
                            predictionTime: etaDate,
                            reservedCount: reservedCount
                        )

                        DispatchQueue.main.async {
                            newScored.append(scored)
                        }

                        group.leave()
                    }
                } else {
                    print("Prediction failed for \(station.stationID)")
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            // Sort current batch by fitScore
            newScored.sort {
                let scoreA = Int($0.fitScore * 100)
                let scoreB = Int($1.fitScore * 100)

                if scoreA == scoreB {
                    return $0.etaMinutes < $1.etaMinutes
                } else {
                    return scoreA > scoreB
                }
            }

            // Add to full list
            self.scoredStations += newScored

            self.scoredStations.sort {
                let scoreA = Int($0.fitScore * 100)
                let scoreB = Int($1.fitScore * 100)

                if scoreA == scoreB {
                    return $0.etaMinutes < $1.etaMinutes
                } else {
                    return scoreA > scoreB
                }
            }

            self.currentBatchIndex += self.batchSize
            self.isLoading = false

        }

    }


    func loadMore() {

        if let params = lastFetchParams {
            loadNextBatch(baseDate: params.2, userLocation: params.1)
        } else {
            print("loadMore called but no params available")
        }
    }
}


struct ReservationChecker {

    static func getReservationCount(
        for stationID: String,
        at timestamp: Date,
        completion: @escaping (Int?) -> Void
    ) {
        let db = Firestore.firestore()
        let start = timestamp
        let end = Calendar.current.date(byAdding: .minute, value: 15, to: timestamp)!

        db.collection("reservations")
            .whereField("stationID", isEqualTo: stationID)
            .whereField("status", isEqualTo: "active")
            .whereField("startTime", isLessThan: end)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("Failed to check reservations: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }

                let count = documents.filter { doc in
                    let docStart =
                        (doc["startTime"] as? Timestamp)?.dateValue()
                        ?? Date.distantPast

                    let blockCount =
                        doc["blockCount"] as? Int ?? 1

                    let docEnd =
                        Calendar.current.date(
                            byAdding: .minute,
                            value: blockCount * 15,
                            to: docStart
                        ) ?? Date.distantPast

                    return docEnd > start
                }.count

                completion(count)
            }
    }
}
