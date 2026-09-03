//
//  ManualInputView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 7.05.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ManualInputView: View {
    @Environment(\.dismiss) var dismiss
    @State private var carModels: [CarModel] = []
    @State private var selectedCarID: String?
    @State private var batteryLevel: String = ""
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var showSuccessMessage = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading car models...")
                    .onAppear(perform: loadCarModels)
            } else if carModels.isEmpty {
                VStack(spacing: 12) {
                    Text("⚠️ Failed to load car models.")
                        .foregroundColor(.red)
                    Button("Retry") {
                        isLoading = true
                        loadCarModels()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Form {
                    Section(header: Text("Car Information")) {
                        Picker("Select your car model", selection: $selectedCarID) {
                            ForEach(carModels, id: \.id) { car in
                                Text(car.name).tag(car.id as String?)
                            }
                        }
                    }

                    Section(header: Text("Battery Information"), footer: Text("Enter your current battery level between 0 and 100 percent.")) {
                        TextField("Battery level (%)", text: $batteryLevel)
                            .keyboardType(.decimalPad)
                    }

                    Section {
                        Button(isSubmitting ? "Submitting..." : "Submit") {
                            submit()
                        }
                        .disabled(!isValidInput || isSubmitting)

                        if showSuccessMessage {
                            Text("✅ Your car info was saved!")
                                .foregroundColor(.green)
                        }
                    }
                }
                .disabled(isSubmitting)
            }
        }
        .padding()
        .navigationTitle("Enter Vehicle Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    var isValidInput: Bool {
        guard let _ = selectedCarID else { return false }
        guard let val = Float(batteryLevel), (0...100).contains(val) else { return false }
        return true
    }

    func loadCarModels() {
        let db = Firestore.firestore()
        db.collection("car_models")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Failed to load car models: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found in car_models")
                    isLoading = false
                    return
                }

                do {
                    self.carModels = try documents.map { try $0.data(as: CarModel.self) }
                    self.isLoading = false
                } catch {
                    print("❌ Decoding error: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
    }

    func submit() {
        guard isValidInput,
              let selectedCarID = selectedCarID,
              let selectedCar = carModels.first(where: { $0.id == selectedCarID }),
              let batteryLevelFloat = Float(batteryLevel),
              (0...100).contains(batteryLevelFloat)
        else {
            print("Invalid input")
            return
        }

        isSubmitting = true
        UserSessionManager.shared.updateManualCarInfo(
            car: selectedCar,
            batteryLevel: batteryLevelFloat
        ) { error in
            isSubmitting = false
            if let error = error {
                print("❌ Firestore update failed: \(error.localizedDescription)")
            } else {
                print("✅ Firestore update success")
                UserSessionManager.shared.shouldCompleteManualCarInfo = false
                UserSessionManager.shared.fetchUserEVInfo()
                showSuccessMessage = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

