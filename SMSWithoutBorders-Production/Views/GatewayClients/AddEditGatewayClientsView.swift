//
//  AddEditGatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 03/04/2025.
//

import Contacts
import ContactsUI
import CountryPicker
import SwiftUI

enum FormFieldFocus {
    case phoneNumber
    case alias
}


struct AddEditGatewayClientView: View {
    //Core data context
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @State private var phoneNumber: String
    @State private var operatorAlias: String
    @State var gatewayClient: GatewayClients?
    @State private var originalMsisdn: String?
    @State private var isEditing: Bool
    @State private var country: Country? = Country.init(isoCode: "CM")
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName


    @State private var showCountryPicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var isSuccessful: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""


    @Binding var defaultMsisdnStorage: String
    @State private var contactPickerService = ContactPickerService()
    @FocusState private var focus: FormFieldFocus?
    let onDismiss: () -> Void

    init(gatewayClient: GatewayClients? = nil, defaultMsisdnStorage: Binding<String>, onDismissed: @escaping () -> Void) {
        _gatewayClient = State(initialValue: gatewayClient)
        self._defaultMsisdnStorage = defaultMsisdnStorage
        self._isEditing = State(initialValue: (gatewayClient != nil))
        self.phoneNumber = ""
        self.operatorAlias = ""
    
        self.onDismiss = onDismissed

        if let client = gatewayClient {
            print("edit mode client.operator alisa: \(client.operator)")
            // Editing Mode
            let countryIsoCode: String = CountryUtils.getISoCode(fromFullName: client.country) ?? "CM"
            _country = State(initialValue: Country(isoCode: countryIsoCode))
            _phoneNumber = State(initialValue: CountryUtils.getLocalNumber(fullNumber: client.msisdn, isoCode: countryIsoCode) ?? "")
            _operatorAlias = State(initialValue: client.operator)
            _originalMsisdn = State(initialValue: client.msisdn)

            print("INIT (Editing) : country=\(client.country), phoneNumber=\(client.msisdn), alias=\(client.operator)")

        } else {
            // Adding Mode
            let defualtCountry = Country(isoCode: "CM")
            _country = State(initialValue: defualtCountry)
            _phoneNumber = State(initialValue: "")
            _operatorAlias = State(initialValue: "")
            print("INIT (Adding) : Defualting state")
        }
    }


    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 32)
            Text("Phone Number").font(RelayTypography.bodyMedium)
            HStack {
                // Country Picker Button
                Button {
                    showCountryPicker = true
                } label: {
                    let flag = country!.isoCode
                    Text(flag.getFlag() + "+" + (country!.phoneCode))
                        .foregroundColor(RelayColors.colorScheme.onSurface)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 8)
                }.sheet(isPresented: $showCountryPicker) {
                    CountryPicker(
                        country: $country,
                        selectedCountryCodeText: $selectedCountryCodeText)
                }.background(RelayColors.colorScheme.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField(
                    "Phone Number",
                    text: $phoneNumber
                )
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textFieldStyle(RelayTextFieldStyle())
                .focused($focus, equals: .phoneNumber)
                .onAppear {
                    focus = FormFieldFocus.phoneNumber
                }.onSubmit {
                    focus = FormFieldFocus.alias
                }

                // Contact Picker Button
                Button {
                    contactPickerService.openContactPicker()
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }.onReceive(contactPickerService.delegate.$localPhoneNumber) { phoneNum in
                    // Sets the phone number from the selected phone number
                    if let number = phoneNum {
                        phoneNumber = number
                    }
                }.onReceive(contactPickerService.delegate.$phoneCode) { phoneCode in
                    print("selected phone code: \(phoneCode ?? "N/A")")
                    
                    // Sets the country of the selected phone number if available
                    if let code = phoneCode {
                        let countryName: String?  = CountryUtils.getCountryNameFromPhoneCode(phoneCode: code)
                        print("countryName: \(countryName ?? "N/A")")
                        
                        if let name = countryName {
                            let isoCode = CountryUtils.getISoCode(fromFullName: name)
                            country = Country.init(isoCode: isoCode!)
                        }
                    }

                }.onReceive(contactPickerService.delegate.$name) { name in
                    if let contactName = name {
                        operatorAlias = contactName
                    }
                }

            }
            Spacer().frame(height: 16)
            Text("Alias").font(RelayTypography.bodyMedium)
            TextField(
                "Operator Alias", text: $operatorAlias
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .textFieldStyle(RelayTextFieldStyle())
            .focused($focus, equals: .alias)

            Spacer().frame(height: 32)
            Spacer()

            Button(isEditing ? "Update Gateway Client" : "Add Gateway Client", systemImage: isEditing ? "pencil" : "plus") {
                
                // Validate Information
                if phoneNumber.isEmpty {
                    showAlert = true
                    alertTitle = "Error"
                    alertMessage = "Please input a phone number."
                    isSuccessful = false
                    return
                }
                
                
                // Create the GatewayClientEntity to add
                let newClient: GatewayClients = GatewayClients(
                    country: country!.localizedName,
                    last_published_date: 0,
                    msisdn: "+\(country!.phoneCode)\(phoneNumber)",
                    operator: operatorAlias,
                    operator_code: "",
                    protocols: [],
                    reliability: ""
                )

                do {
                    // Save the gatewayClient
                    if isEditing, let oldMsisdn = originalMsisdn {
                        try GatewayClients.updateGatewayClient(
                            context: context,
                            oldClientMsisdn: oldMsisdn,
                            newClient: newClient)

                        // Update AppStorage if default MSISDN Changed
                        let newMsisdn = newClient.msisdn
                        if oldMsisdn == self.defaultMsisdnStorage && oldMsisdn != newMsisdn {
                            print("Default client MSISDN changed from \(oldMsisdn) to \(newMsisdn). Updating AppStorage.")
                            self.defaultMsisdnStorage = newMsisdn
                        }
                        
                        // Successfully updated the client
                        isSuccessful = true
                        alertTitle = "Success"
                        alertMessage = "Successfully saved client"
             
                    } else {
                        try GatewayClients.addGatewayClient(context: context, client: newClient)
                        
                        // Successfully added the client
                        isSuccessful = true
                        alertTitle = "Success"
                        alertMessage = "Successfully added client"
                    }
                    showAlert = true
                } catch {
                    // Error Occureed
                    if isEditing {
                        isSuccessful = false
                        alertTitle = "Error"
                        alertMessage = "Unable to update Gateway Client"
                        print("Unable to update Gateway Client")
                    } else {
                        print("Unable to add Gateway Client")
                        isSuccessful = false
                        alertTitle = "Error"
                        alertMessage = "Unable to add Gateway Client"
                    }
                    showAlert = true
                }
            }.buttonStyle(.relayButton(variant: .primary))
            Spacer().frame(height: 64)

        }.padding([.leading, .trailing], 16)
            .navigationTitle(isEditing ? "Edit Gateway Client" : "Add Gateway Client")

            .alert(
                isPresented: $showAlert,
                content: {
                    let dismissButton: Alert.Button = .default(Text("OK")) {
                        showAlert = false
                        if isSuccessful {
                            dismiss()
                            onDismiss()
                        }
                    }
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: dismissButton
                    )
                }
            )


    }



}
