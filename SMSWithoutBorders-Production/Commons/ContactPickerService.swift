//
//  ContactPickerService.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 03/04/2025.
//

import Combine
import Contacts
import ContactsUI

import SwiftUI


class ContactPickerService {
    
    @Published var delegate = ContactPickerServiceDelegate()
   
    func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = delegate
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(contactPicker, animated: true, completion: nil)
    }
}


class ContactPickerServiceDelegate: NSObject, ObservableObject, CNContactPickerDelegate {
    var pickedNumber: String?
    @Published var internationPhoneNumber: String?
    @Published var localPhoneNumber: String?
    @Published var isoCode: String?
    @Published var rawValue: String?

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        // Clear the pickedNumber initially
        self.pickedNumber = nil

        // Check if the contact has selected phone numbers
        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
            handlePhoneNumber(phoneNumber)
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {

        if contactProperty.key == CNContactPhoneNumbersKey,
           let phoneNumber = contactProperty.value as? CNPhoneNumber {

            let phoneNumberString = phoneNumber.stringValue
            // Now phoneNumberString contains the phone number
            print("Phone Number: \(phoneNumberString)")

            // You can now use phoneNumberString as needed
            handlePhoneNumber(phoneNumberString)
        }
    }

    private func handlePhoneNumber(_ phoneNumber: String) {
//        let phoneNumberWithoutSpace = phoneNumber.replacingOccurrences(of: " ", with: "")
//
//        // Check if the phone number starts with "+"
//        let sanitizedPhoneNumber = phoneNumberWithoutSpace.hasPrefix("+") ? String(phoneNumberWithoutSpace.dropFirst()) : phoneNumberWithoutSpace
        
        // Remove isocode from phone number

        
        let localNumber = phoneNumber.starts(with: "+") ? phoneNumber.split(separator: " ").dropFirst().joined(separator: " ") : phoneNumber
        var cleanedNumber = localNumber.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "") // This should remove these characters " "(", ")", "-", and " "
        let isoCode: String = phoneNumber.starts(with: "+") ? String(phoneNumber.split(separator: " ").first ?? "") : ""

        DispatchQueue.main.async {
            //self.localPhoneNumber = sanitizedPhoneNumber
            self.isoCode = isoCode
            self.localPhoneNumber = cleanedNumber
            self.internationPhoneNumber = isoCode.isEmpty ? nil : "\(isoCode)\(cleanedNumber)"
            self.rawValue = phoneNumber

            print("international Phone Number: \(self.internationPhoneNumber ?? "nil") ")
            print("Local Phone Number: \(self.localPhoneNumber ?? "nil") ")
            print("isoCode: \(self.isoCode ?? "nil") ")
            print("rawValue: \(self.rawValue ?? "nil") ")
        }
    }

}




