//
//  ReservationView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 18.05.2025.
//


import SwiftUI

struct ReservationView: View {
    let station: ChargingStation
    let startTime: Date

    @Environment(\.dismiss) var dismiss
    @StateObject private var reservationVM = ReservationViewModel()
    @State private var selectedBlockCount: Int = 1
    


    

    var body: some View {
        
            Form {
                Section(header: Text("Reservation Details")) {
                    Text("Station ID: \(station.stationID)")
                    Text("Start Time: \(formattedStartTime)")
                    Picker("Duration (15-min blocks)", selection: $selectedBlockCount) {
                        ForEach(1...4, id: \ .self) { count in
                            Text("\(count * 15) minutes").tag(count)
                        }
                    }
                }

                Section {
                    if reservationVM.isLoading {
                        ProgressView("Checking availability...")
                    } else {
                        Button("Confirm Reservation") {
                            reserve()
                        }
                    }
                }

                if let error = reservationVM.reservationError {
                    Section {
                        Text(" \(error)")
                            .foregroundColor(.red)
                    }
                }

                if reservationVM.reservationSuccess {
                    Section {
                        Text("Reservation confirmed!")
                            .foregroundColor(.green)
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Reserve Slot")
        }
    
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Europe/Paris") //  force Paris zone
        return formatter.string(from: startTime)
    }


    func reserve() {
        reservationVM.createReservation(
            station: station,
            startTime: startTime,
            blockCount: selectedBlockCount
        ) { _ in }
    }

}
