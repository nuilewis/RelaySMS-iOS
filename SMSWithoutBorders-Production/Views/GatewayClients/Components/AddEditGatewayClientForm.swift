//
//  AddEditGatewayClientForm.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/03/2025.
//

import CoreData
import CountryPicker
import SwiftUI

struct AddEditGatewayClientForm: View {
    //Core data context
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @Binding private var isPresented: Bool
    @State private var phoneNumber: String
    @State private var operatorAlias: String
    @State var gatewayClient: GatewayClients?
    @State private var originalMsisdn: String?
    @State private var isEditing: Bool
    @State private var country: Country? = Country.init(isoCode: "CM")
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName


    @State private var showCountryPicker: Bool = false
    @State private var showToast: Bool = false
    @State private var isSuccessful: Bool = false


    @Binding var defaultMsisdnStorage: String


    init(gatewayClient: GatewayClients? = nil, isPresented: Binding<Bool>, defaultMsisdnStorage: Binding<String>) {

        _gatewayClient = State(initialValue: gatewayClient)
        self._defaultMsisdnStorage = defaultMsisdnStorage
        self._isPresented = isPresented
        self._isEditing = State(initialValue: (gatewayClient != nil))
        self.phoneNumber = ""
        self.operatorAlias = ""

        if let client = gatewayClient {
            // Editing Mode
            let countryIsoCode: String = CountryUtils.getISoCode(fromFullName: gatewayClient!.country) ?? "CM"
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
        VStack {
            Text(isEditing ? "Edit Gateway Client" : "Add Gateway Client").font(RelayTypography.titleLarge)
            Spacer().frame(height: 32)
            HStack {
                Button {
                    showCountryPicker = true
                } label: {
                    let flag = country!.isoCode
                    Text(flag.getFlag() + "+" + (country!.phoneCode))
                        .foregroundColor(RelayColors.colorScheme.onSurface)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                }.sheet(isPresented: $showCountryPicker) {
                    CountryPicker(
                        country: $country,
                        selectedCountryCodeText: $selectedCountryCodeText)
                }.background(RelayColors.colorScheme.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField("Phone Number", text: $phoneNumber)
                    .onSubmit {
                        //TODO: Validate Phone Number
                    }
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textFieldStyle(RelayTextFieldStyle())
            }

            Spacer().frame(height: 16)
            TextField("Operator Alias", text: $operatorAlias)
                .onSubmit {
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textFieldStyle(RelayTextFieldStyle())
            Spacer().frame(height: 32)

            Button(isEditing ? "Update Gateway Client" : "Add Gateway Client", systemImage: isEditing ? "pencil" : "plus") {
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
                    } else {
                        try GatewayClients.addGatewayClient(context: context, client: newClient)
                    }

                    isSuccessful = true
                    showToast = true
                } catch {
                    if isEditing {
                        print("Unable to update GatewayClient")
                    } else {
                        print("Unable to add GatewayClient")
                    }

                    isSuccessful = false
                    showToast = true
                }
            }.buttonStyle(.relayButton(variant: .primary))
        }.padding([.leading, .trailing], 16)
            .navigationTitle(isEditing ? "Edit Client" : "Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
            }.alert(
                isPresented: $showToast,
                content: {

                    let dismissButton: Alert.Button = .default(Text("OK")) {
                        showToast = false
                        if isSuccessful {
                            isPresented = false
                            dismiss()
                        }
                    }

                    var message: LocalizedStringKey
                    if isEditing {
                        if isSuccessful {
                            message = "Successfully saved client"
                        } else {
                            message = "Unable to save client"
                        }
                    } else {
                        if isSuccessful {
                            message = "Successfully added client"
                        } else {
                            message = "Unable to add client"
                        }
                    }

                    return Alert(
                        title: Text(isSuccessful ? "Success" : "Error"),
                        message: Text(message),
                        dismissButton: dismissButton
                    )
                }
            )
    }
}
