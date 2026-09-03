//
//  EVChargingReservationApp.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 18.03.2025.
//

import SwiftUI
import FirebaseCore
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      if let key = SecretsManager.getAPIKey(for: "GoogleMapsPlatformAPIKey") {
          GMSServices.provideAPIKey(key)
      } else {
          print("Missing Google Maps API key!")
      }

    return true
  }
}


@main
struct EVChargingReservationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
            }
        }
    }
}


