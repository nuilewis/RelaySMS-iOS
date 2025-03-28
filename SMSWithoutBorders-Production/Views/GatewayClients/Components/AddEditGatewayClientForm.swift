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
    @State private var phoneNumber: String
    @State private var operatorAlias: String
    @State var gatewayClient: GatewayClients?
    @State private var isEditing: Bool
    @State private var country: Country? = Country.init(isoCode: "CM")
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName


    @State private var showCountryPicker: Bool = false
    @State private var showToast: Bool = false
    @State private var isSuccessful: Bool = false
    @Binding private var isPresented: Bool

    init(gatewayClient: GatewayClients? = nil, isPresented: Binding<Bool>) {
        self.phoneNumber = ""
        self.operatorAlias = ""
        self.gatewayClient = gatewayClient
        self._isPresented = isPresented
        isEditing = gatewayClient != nil

        if isEditing {
            phoneNumber = gatewayClient!.msisdn
            operatorAlias = gatewayClient!.country
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

            Button(isEditing ? "Update Gateway Client" : "Add Gateway Client", systemImage: "add") {
                // Create the GatewayClientEntity to add

                let gatewayClient: GatewayClients = GatewayClients(
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
                    try GatewayClients.addGatewayClient(context: context, client: gatewayClient)
                    isSuccessful = true
                    showToast = true
                } catch {
                    print("Unable to add GatewayClient")
                    isSuccessful = false
                    showToast = true
                }
            }.buttonStyle(.relayButton(variant: .primary)).alert(
                isPresented: $showToast,
                content: {
                    Alert(
                        title: Text(isSuccessful ? "Successfully added client" : "Unable to add client"),
                        primaryButton: .default(
                            Text("OK"),
                            action: {
                                showToast = false
                                isPresented = false
                            }),
                        secondaryButton: .destructive(Text("Nothing"))

                    )
                })
        }.padding([.leading, .trailing], 16)
    }
}

#Preview {
    @State var isPresented: Bool = true
    AddEditGatewayClientForm(isPresented: $isPresented).previewLayout(.sizeThatFits)
}
