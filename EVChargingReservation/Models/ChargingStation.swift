//
//  ChargingStation.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 19.03.2025.

// Defines the charging station data structure.

import Foundation
import CoreLocation

struct ChargingStation: Identifiable {
    var id: String { stationID } 
    
    let stationID: String
    let coordinate: CLLocationCoordinate2D
    let postcode: Int
    let area: String
    let totalPlugs: Int
}

