//
//  CarModel.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 7.05.2025.
//

import Foundation
import FirebaseFirestore

struct CarModel: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var avgConsumptionRate: Float
    var batteryCapacity: Float
}
