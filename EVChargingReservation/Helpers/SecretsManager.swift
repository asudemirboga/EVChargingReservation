//
//  SecretsManager.swift
//  EVChargingReservation
//
//  Created by Asude Beyza DEMİRBOĞA on 19.03.2025.
//

import Foundation

struct SecretsManager{
    // static function --> no need to have an instance of the struct to use the func.
    static func getAPIKey(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else { return nil }
        return plist[key] as? String
    }
}

