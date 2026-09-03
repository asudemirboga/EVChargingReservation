//
//  LocationManager.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 22.03.2025.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationManager()

    @Published var userLocation: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            return
        }

        userLocation = location.coordinate
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
