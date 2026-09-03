//
//  UserReservationsView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 20.05.2025.
//

import SwiftUI
import CoreLocation

struct UserReservationsView: View {
    @StateObject private var reservationVM = ReservationViewModel()
    @State private var selectedReservation: Reservation? = nil
    @State private var navigateToMap: Bool = false

    var body: some View {
        NavigationStack {
            List {
                
                Section(header: Text("My EV Information")) {
                    HStack {
                        Text("Car Model:")
                        Spacer()
                        Text(UserSessionManager.shared.carModel ?? "-")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Battery Level:")
                        Spacer()
                        if let battery = UserSessionManager.shared.batteryLevel {
                            Text("\(Int(battery))%")
                                .foregroundColor(.gray)
                        } else {
                            Text("-")
                                .foregroundColor(.gray)
                        }
                    }
                }

                
                Section(header: Text("My Reservations")) {
                    if reservationVM.userReservations.isEmpty {
                        Text("No active reservations found.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(reservationVM.userReservations) { reservation in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Station: \(reservation.stationID)")
                                    .font(.headline)

                                Text("Start: \(format(date: reservation.startTime))")
                                    .font(.subheadline)

                                Text("Duration: \(reservation.formattedDuration)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)

                                HStack(spacing: 16) { // spacing between buttons
                                    // Navigate Button
                                    Button {
                                        selectedReservation = reservation
                                        navigateToMap = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "location.fill")
                                            Text("Navigate")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)

                                    // Cancel Button
                                    Button {
                                        reservationVM.cancelReservation(reservation) { _ in }
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                            Text("Cancel")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                                .frame(height: 44)
                                .padding(.top, 6)

                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .onAppear {
                reservationVM.fetchUserReservations()
                UserSessionManager.shared.fetchUserEVInfo()
            }

            
            NavigationLink(
                destination: selectedReservation.map { res in
                    DirectionScreen(destination: res.coordinate)
                },
                isActive: $navigateToMap,
                label: { EmptyView() }
            )
            .hidden()
        }
    }

    func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

