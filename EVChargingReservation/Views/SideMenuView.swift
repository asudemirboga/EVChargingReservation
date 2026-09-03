//
//  SideMenuView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 6.05.2025.
//

import SwiftUI

struct SideMenuView: View {
    @State private var showLogoutAlert = false
    private let session = UserSessionManager.shared

    var body: some View {
        VStack {
            Spacer()

            Button(action: {
                showLogoutAlert = true
            }) {
                Label("Log Out", systemImage: "arrow.backward.square")
                    .padding()
                    .foregroundColor(.red)
            }
            .alert("Confirm Logout", isPresented: $showLogoutAlert) {
                Button("Logout", role: .destructive) {
                    session.logout()
                }
                Button("Cancel", role: .cancel) {}
            }

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.all)
        .alignmentGuide(.leading) { _ in 0 } 
    }
}
