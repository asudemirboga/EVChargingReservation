//
//  NavigationMapView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 16.05.2025.
//

import SwiftUI
import GoogleMaps

struct NavigationMapView: UIViewRepresentable {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let path: GMSPath?

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()

        mapView.camera = GMSCameraPosition.camera(
            withLatitude: origin.latitude,
            longitude: origin.longitude,
            zoom: 13
        )
        
        // Origin marker
        let originMarker = GMSMarker()
        originMarker.position = origin
        originMarker.icon = GMSMarker.markerImage(with: .blue)
        originMarker.title = "Your Location"
        originMarker.map = mapView

        let destMarker = GMSMarker(position: destination)
        destMarker.title = "Station"
        destMarker.map = mapView

        if let path = path {
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .blue
            polyline.strokeWidth = 4
            polyline.map = mapView
        }
    }
}


//  DirectionScreen.swift
//  EVChargingReservation

import SwiftUI
import GoogleMaps
struct DirectionScreen: View {
    let destination: CLLocationCoordinate2D
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var routePath: GMSPath?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let userLoc = locationManager.userLocation {
                    VStack(spacing: 16) {
                        Text("Navigating to your selected charging station")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.top, 12)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)

                        NavigationMapView(origin: userLoc, destination: destination, path: routePath)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                    .onAppear {
                        NavigationHelper.fetchRoute(from: userLoc, to: destination) { path in
                            DispatchQueue.main.async {
                                self.routePath = path
                            }
                        }
                    }
                } else {
                    Spacer()
                    ProgressView("Getting location...")
                    Spacer()
                }
            }
            .padding(.top, 12)
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
