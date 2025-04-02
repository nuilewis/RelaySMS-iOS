//
//  GatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import SwiftUI

struct GatewayClientsView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor(
            key: "msisdn",
            ascending: true)
    ]
    ) var gatewayClients: FetchedResults<GatewayClientsEntity>

    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State var selectedGatewayClientMsisdn: String = ""
    @State var changeDefaultGatewayClient: Bool = false
    @State var addGatewayClientSheetPresented: Bool = false
    @State var showDeletedNotification: Bool = false
    @State var isSuccessful: Bool = false

    @State var defaultGatewayClient: GatewayClientsEntity?

    var body: some View {
        NavigationView {
            VStack {
                if defaultGatewayClient != nil {
                    VStack {
                        Text("Selected Gateway client")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption2)
                            .padding(.bottom, 3)
                            .foregroundColor(.secondary)
                        GatewayClientCard(clientEntity: defaultGatewayClient!, disabled: true)
                            .padding(.top, 3)
                    }
                    .padding()
                }

                Button("Add Gateway Client", systemImage: "add") {
                    addGatewayClientSheetPresented = true
                }.buttonStyle(.relayButton(variant: .secondary))
                    .padding(.horizontal, 16).padding(
                        .bottom, 16
                    )
                    .sheet(
                        isPresented: $addGatewayClientSheetPresented,
                        onDismiss: {
                            addGatewayClientSheetPresented = false
                        },
                        content: {
                            AddEditGatewayClientForm(isPresented: $addGatewayClientSheetPresented)
                        })

                List(gatewayClients, id: \.self) { gatewayClient in
                    Button(action: {
                        if let msisdn = gatewayClient.msisdn {
                            selectedGatewayClientMsisdn = msisdn
                            changeDefaultGatewayClient = true
                        } else {
                            print("No MSISDN found, MSISDN is nil")
                            //TODO: Maybe show an alert or something
                        }




                    }) {
                        GatewayClientCard(clientEntity: gatewayClient, disabled: false)
                            .padding()
                    }
                }
                .confirmationDialog(
                    "Set as default gateway client?",
                    isPresented: $changeDefaultGatewayClient
                ) {
                    Button("Make default") {
                        defaultGatewayClientMsisdn = selectedGatewayClientMsisdn
                    }
                } message: {
                    Text(String(localized: "Choosing a Gateway client in the same Geographical location as you helps improves the reliability of your messages being delivered", comment: "Explains that selecting a Gateway clinet int he same geographical localtiion helps improve the reliability of yout messages"))
                }
            }
            .navigationTitle("Countries")
        }
        .onChange(of: defaultGatewayClientMsisdn) { state in
            defaultGatewayClient = getDefaultGatewayClient()
        }
        .onAppear {
            if !defaultGatewayClientMsisdn.isEmpty {
                defaultGatewayClient = getDefaultGatewayClient()
            }
        }
    }

    func getDefaultGatewayClient() -> GatewayClientsEntity? {
        gatewayClients.filter {
            $0.msisdn == defaultGatewayClientMsisdn
        }
        .first
    }
}

struct GatewayClientsView_Previoew: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return GatewayClientsView()
            .environment(\.managedObjectContext, container.viewContext)
    }
}
