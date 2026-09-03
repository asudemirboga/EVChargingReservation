//
//  WelcomeView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 20.03.2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
                    VStack(spacing: 30) {
                Text("Smart EV Charging")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 70)
                
                Image(systemName: "bolt.car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Efficient and Smart EV Charging Reservation")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        showLogin = true
                    }) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(navigateToLogin: $showLogin)
            }

        }
    }

