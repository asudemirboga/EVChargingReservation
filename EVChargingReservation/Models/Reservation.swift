//
//  Reservation.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 20.05.2025.
//

import Foundation
import FirebaseFirestore
import CoreLocation

struct Reservation: Identifiable, Codable {
    @DocumentID var id: String?
    let userID: String
    let stationID: String
    let stationLatitude: Double
    let stationLongitude: Double
    let startTime: Date
    let startTimeFormatted: String
    let blockCount: Int
    var status: String
    let createdAt: Date
    
    var duration: Int {
        blockCount * 15 // minutes
    }
    
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startTime)!
    }
    
    var formattedDuration: String {
        "\(duration) minutes"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case stationID
        case stationLatitude
        case stationLongitude
        case startTime
        case startTimeFormatted
        case blockCount
        case status
        case createdAt
    }
}
