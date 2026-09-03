//
//  RootView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 6.05.2025.
//

import SwiftUI

struct RootView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoggedIn {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
        }
    }
}



