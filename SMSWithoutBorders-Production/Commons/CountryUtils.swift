//
//  CountryUtils.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 01/04/2025.
//

import SwiftUI
import CountryPicker

struct CountryUtils {

    static func getISoCode(fromFullName fullName: String) -> String? {

        let allCountries: [Country] = CountryManager.shared.getCountries()

        let normalizedInputName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let foundCountry = allCountries.first {
            country in
            let normalizedLibaryName = country.localizedName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return normalizedLibaryName == normalizedInputName
        }

        return foundCountry?.isoCode
    }
    
    static func getCountryNameFromPhoneCode(phoneCode: String) -> String? {
        let allCountries: [Country] = CountryManager.shared.getCountries()
        
        let foundCountry = allCountries.first {
            country in
        
            let countryCode = country.phoneCode
            print("country code is : \(countryCode)")
            return countryCode == phoneCode.replacingOccurrences(of: "+", with: "")
        }
        
        return foundCountry?.localizedName
    }


    static func getLocalNumber(fullNumber: String, isoCode: String) -> String? {
        var phoneCode: String = "+" + Country.init(isoCode: isoCode).phoneCode
        var phoneNumber: String = fullNumber
        phoneNumber = phoneNumber.replacingOccurrences(of: phoneCode, with: "")

        print("local phone number from \(fullNumber) with country iso code \(isoCode) is: \(phoneNumber)")
        
        return phoneNumber
    }
}
