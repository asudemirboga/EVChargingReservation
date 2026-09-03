//
//  LoginView.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 20.03.2025.
//


import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private let session = UserSessionManager.shared

    enum Field {
        case email, password
    }

    var body: some View {
        VStack {
            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 40)

            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal, 40)
            }

           
            Button(action: {
                session.logIn(email: email, password: password) { error in
                    if let error = error {
                        self.errorMessage = error
                    } else {
                        dismiss()
                    }
                }
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 20)
            .disabled(email.isEmpty || password.isEmpty)

            
            Button(action: {
                forgotPassword()
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
            .padding(.top, 5)

            Spacer()
        }
        .navigationTitle("Log In")
    }

    func forgotPassword() {
        if email.isEmpty {
            errorMessage = "Please enter your email to reset password."
            return
        }

        session.resetPassword(email: email) { message in
            self.errorMessage = message
        }
    }
}
