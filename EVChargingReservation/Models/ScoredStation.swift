//
//  ScoredStation.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 23.04.2025.
//

import Foundation
import CoreLocation

struct ScoredStation: Identifiable {
    var id: String { station.stationID } 
    let station: ChargingStation
    let etaMinutes: Int
    let fitScore: Double
    let predictionTime: Date
    let reservedCount: Int
}

