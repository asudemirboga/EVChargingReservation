//
//  BestSlotView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 11.05.2025.
//

import SwiftUI
import CoreLocation
import Firebase

struct BestSlotView: View {
    @ObservedObject private var session = UserSessionManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @StateObject private var stationVM = AvailableStationsViewModel()
    @State private var carModels: [CarModel] = []
    
    @State private var hasLoadedOnce = false // to load car models once
    @State private var carSelectionWorkItem: DispatchWorkItem? // to wait while car selection
    @State private var updatedBatteryLevel: Double = 50.0
    @State private var batteryThreshold: Double = 20.0
    @State private var selectedDate = Date()
    @State private var isShowingResults = false // for directing PredictedStationsListView
    @State private var selectedCarID: String?
    @State private var isLoadingCarModels = false
    @State private var showChangeCarModel = false // on car change to show picker

    
    var needsCarInfo: Bool {
        return session.shouldCompleteManualCarInfo
            || session.carModel == nil
            || session.avgConsumptionRate == nil
            || session.batteryCapacity == nil
        
    }
    
    var isBatteryChanged: Bool {
        Int(updatedBatteryLevel) != Int(session.batteryLevel ?? 50)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {

                    Text("Plan your charging slot based on your car model, battery level, and preferred arrival threshold.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Car Model Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Car Model")
                            .font(.headline)

                        if needsCarInfo || showChangeCarModel {
                            Picker("Please select your car model", selection: $selectedCarID) {
                                ForEach(carModels, id: \.id) { car in
                                    Text(car.name).tag(car.id as String?)
                                }
                            }
                            .pickerStyle(.wheel)
                            .onChange(of: selectedCarID) { newID in
                                // İptal et önceki bekleyen işi:
                                carSelectionWorkItem?.cancel()
                                
                                
                                let workItem = DispatchWorkItem {
                                    if let selectedCarID = newID,
                                       let selectedCar = carModels.first(where: { $0.id == selectedCarID }) {
                                        UserSessionManager.shared.updateManualCarInfo(
                                            car: selectedCar,
                                            batteryLevel: Float(updatedBatteryLevel)
                                        ) { error in
                                            if let error = error {
                                                print("Failed to update car info: \(error.localizedDescription)")
                                            } else {
                                                session.fetchUserEVInfo()
                                                UserSessionManager.shared.shouldCompleteManualCarInfo = false
                                                showChangeCarModel = false
                                            }
                                        }
                                    }
                                }
                                
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
                                
                                
                                carSelectionWorkItem = workItem
                            }


                            if carModels.isEmpty && !isLoadingCarModels {
                                Button("Retry Loading Models") {
                                    loadCarModels()
                                }
                            } else if isLoadingCarModels {
                                ProgressView("Loading car models...")
                            }
                        } else {
                            HStack {
                                Text("Current car: \(session.carModel ?? "-")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Button("Change Car Model") {
                                    showChangeCarModel = true
                                    loadCarModels()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Battery Level Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Battery Level")
                            .font(.headline)

                        Slider(value: $updatedBatteryLevel, in: 0...100, step: 1)
                        Text("Selected: \(Int(updatedBatteryLevel))%")
                            .font(.subheadline)
                            .foregroundColor(.gray)


                        Button("Save Battery Level") {
                            UserSessionManager.shared.saveBatteryLevel(Float(updatedBatteryLevel)) { error in
                                if let error = error {
                                    print("Battery level update failed: \(error.localizedDescription)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(session.carModel == nil || !isBatteryChanged)
                        .padding(.top, 4)

                        if !isBatteryChanged {
                            Text("Battery level is up-to-date.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Battery Threshold Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Minimum Battery at Arrival")
                            .font(.headline)

                        Slider(
                            value: $batteryThreshold,
                            in: 5...max(5, min(50, updatedBatteryLevel)),
                            step: 1
                        )
                        Text("Will arrive with at least: \(Int(batteryThreshold))%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Search Button
                    Button {
                        if let userLocation = locationManager.userLocation {
                            stationVM.fetchInitialStations(
                                batteryThreshold: batteryThreshold,
                                userLocation: userLocation,
                                baseDate: selectedDate
                            )
                        }
                    } label: {
                        if stationVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Search Best Slots")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(
                        session.batteryLevel == nil ||
                        session.avgConsumptionRate == nil ||
                        session.batteryCapacity == nil ||
                        locationManager.userLocation == nil ||
                        isBatteryChanged
                    )

                    if let error = stationVM.errorMessage {
                        Text("\(error)")
                            .foregroundColor(.red)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .onAppear {
                session.startListeningUserEVInfo()

                
                if let battery = session.batteryLevel {
                    updatedBatteryLevel = battery
                }

                // Load car models only once
                if !hasLoadedOnce {
                    hasLoadedOnce = true
                    loadCarModels()

                }
            }
            .onDisappear {
                session.stopListeningUserEVInfo()
            }
            .onChange(of: session.batteryLevel) { newBatteryLevel in
                if let newBatteryLevel = newBatteryLevel {
                    updatedBatteryLevel = newBatteryLevel
                    if batteryThreshold > newBatteryLevel {
                                batteryThreshold = max(5, newBatteryLevel)
                    }
                }
            }
            
            .onChange(of: updatedBatteryLevel) { newBatteryLevel in
                if batteryThreshold > newBatteryLevel {
                    batteryThreshold = max(5, newBatteryLevel)
                }
            }
            
            .navigationDestination(isPresented: $isShowingResults) {
                PredictedStationListView(viewModel: stationVM)
            }
            .onChange(of: stationVM.scoredStations.isEmpty) { isEmpty in
                if !isEmpty {
                    isShowingResults = true
                }
            }
            .navigationTitle("Smart Charging")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    
    func loadCarModels() {
        isLoadingCarModels = true
        let db = Firestore.firestore()
        db.collection("car_models")
            .getDocuments { snapshot, error in
                isLoadingCarModels = false
                if let error = error {
                    print("Failed to load car models: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found in car_models")
                    return
                }

                do {
                    self.carModels = try documents.map { try $0.data(as: CarModel.self) }
                } catch {
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
    }
}
