//
//  PredictedStationListView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 15.05.2025.
//

import SwiftUI
import CoreLocation

struct PredictedStationListView: View {
    @ObservedObject var viewModel: AvailableStationsViewModel

    var body: some View {
        let bestStationID = viewModel.scoredStations.first?.station.stationID

        List {
            ForEach(viewModel.scoredStations) { station in
                let isBest = station.station.stationID == bestStationID
                PredictedStationRow(station: station, isBest: isBest)
            }

            if viewModel.scoredStations.count < viewModel.allNearbyStations.count {
                Button("Load More") {
                    viewModel.loadMore()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .buttonStyle(.bordered)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Recommended Stations")
        .refreshable {
            refreshStations()
        }
    }
        
        func refreshStations() {
            if let params = viewModel.lastFetchParams {
                viewModel.fetchInitialStations(
                    batteryThreshold: params.0,
                    userLocation: params.1,
                    baseDate: params.2
                )
            }
        }

}

struct PredictedStationRow: View {
    let station: ScoredStation
    let isBest: Bool
    @State private var isShowingDirections = false
    @State private var isShowingReservation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(" \(station.station.stationID)")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(isBest ? .blue : .primary)

                Spacer()

                if isBest {
                    Text("Best Fit")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arrival")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(station.etaMinutes) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Availability")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(station.fitScore * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(station.fitScore >= 0.7 ? .green : (station.fitScore >= 0.5 ? .orange : .red))
                }

                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reservations")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(station.reservedCount) / \(station.station.totalPlugs)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(station.reservedCount >= station.station.totalPlugs ? .red : .green)
                }
            }


            // Buttons Section
            HStack(spacing: 16) {
                // Navigate Button
                Button(action: { isShowingDirections = true }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Navigate")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .background(
                    NavigationLink(
                        destination: DirectionScreen(destination: station.station.coordinate),
                        isActive: $isShowingDirections,
                        label: { EmptyView() }
                    )
                )

                // Reserve Button
                Button(action: { isShowingReservation = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Reserve")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .background(
                    NavigationLink(
                        destination: ReservationView(
                            station: station.station,
                            startTime: station.predictionTime
                        ),
                        isActive: $isShowingReservation,
                        label: { EmptyView() }
                    )
                )
            }
            .frame(height: 44)
            .padding(.top, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(isBest ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isBest ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .listRowSeparator(.hidden)
    }
    

}


