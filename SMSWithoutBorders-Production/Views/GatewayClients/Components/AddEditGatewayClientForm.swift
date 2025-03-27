//
//  AddEditGatewayClientForm.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/03/2025.
//

import SwiftUI
import CountryPicker

struct AddEditGatewayClientForm: View {

    @State private var phoneNumber: String
    @State private var alias: String
    @State var gatewayClient: GatewayClients?
    @State private var isEditing: Bool
    @State private var country: Country?
    @State private var showCountryPicker = false
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName

    init(gatewayClient: GatewayClients? = nil) {
        self.phoneNumber = ""
        self.alias = ""
        self.gatewayClient = gatewayClient
        isEditing = gatewayClient != nil

        if isEditing {
            phoneNumber = gatewayClient!.msisdn
            alias = gatewayClient!.country
        }
    }


    var body: some View {
        VStack {
            Text(isEditing ? "Edit Gateway Client" : "Add Gateway Client").font(RelayTypography.titleLarge)
            Spacer().frame(height: 32)
            HStack{
                Button {
                    showCountryPicker = true
                } label: {
                    let flag = country?.isoCode ?? Country.init(isoCode: "CM").isoCode
                    Text(flag.getFlag() + "+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                        .foregroundColor(RelayColors.colorScheme.onSurface)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                }.sheet(isPresented: $showCountryPicker) {
                    CountryPicker(country: $country,
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
            TextField("Alias", text: $alias)
                .onSubmit {
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textFieldStyle(RelayTextFieldStyle())
            Spacer().frame(height: 32)

            Button(isEditing ? "Update Gateway Client" : "Add Gateway Client", systemImage: "add") {

            }.buttonStyle(.relayButton(variant: .primary))
        }.padding([.leading, .trailing], 16)
    }
}

#Preview {

    //    var testClient: GatewayClients = GatewayClients(
    //        from: "",
    //        country: "Cameroon",
    //        msisdn: "",
    //    )
    //
    AddEditGatewayClientForm().previewLayout(.sizeThatFits)
}
