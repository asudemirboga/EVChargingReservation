//
//  MapView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 19.03.2025.
//

import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var stations: [ChargingStation]
    @Binding var selectedStationID: String?

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        mapView.camera = GMSCameraPosition.camera(
            withLatitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: 14
        )
        
        
        let myMarker = GMSMarker()
        myMarker.position = coordinate
        myMarker.icon = GMSMarker.markerImage(with: .blue)
        myMarker.title = "Your Location"
        myMarker.map = mapView

        for station in stations {
            let marker = GMSMarker()
            marker.position = station.coordinate
            marker.title = "EV Station"
            marker.userData = station.stationID
            marker.map = mapView
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let stationID = marker.userData as? String {
                parent.selectedStationID = stationID
            }
            return false
        }
    }
}

struct MapScreen: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @StateObject private var stationVM = ChargingStationViewModel()
    @State private var selectedStationID: String?
    @State private var selectedStationDetail: ChargingStation?
    @State private var searchText: String = ""

    var filteredStations: [ChargingStation] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stationVM.stations
        } else {
            return stationVM.stations.filter {
                $0.stationID.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Search box
                TextField("Search charging station...", text: $searchText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Map
                if let coordinate = locationManager.userLocation {
                    GoogleMapView(
                        coordinate: coordinate,
                        stations: filteredStations,
                        selectedStationID: $selectedStationID
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
                } else {
                    ProgressView("Locating...")
                        .frame(maxHeight: .infinity)
                }
            }

            
            .onAppear {
                if let coordinate = locationManager.userLocation {
                    UserSessionManager.shared.fetchNearbyStations(from: coordinate) { stations in
                        DispatchQueue.main.async {
                            stationVM.stations = stations
                        }
                    }
                }
            }

           
            .onChange(of: locationManager.userLocation?.latitude) { _ in
                if let coordinate = locationManager.userLocation {
                    UserSessionManager.shared.fetchNearbyStations(from: coordinate) { stations in
                        DispatchQueue.main.async {
                            stationVM.stations = stations
                        }
                    }
                }
            }

            
            .onChange(of: selectedStationID) { stationID in
                if let stationID = stationID {
                    UserSessionManager.shared.fetchStationDetail(stationID: stationID) { station in
                        DispatchQueue.main.async {
                            if let station = station {
                                self.selectedStationDetail = station
                            }
                        }
                    }
                }
            }

            
            .sheet(item: $selectedStationDetail) { station in
                NavigationStack {
                    VStack(spacing: 12) {
                        Text("Station ID: \(station.stationID)").font(.headline)
                        Text("Area: \(station.area)")
                        Text("Postcode: \(station.postcode)")
                        Text("Total Plugs: \(station.totalPlugs)")

                        Divider()
                            .padding(.vertical, 8)

                        // Navigate Button
                        NavigationLink(destination: DirectionScreen(destination: station.coordinate)) {
                            Label("Navigate", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding()
                    .presentationDetents([.fraction(0.4)])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}
