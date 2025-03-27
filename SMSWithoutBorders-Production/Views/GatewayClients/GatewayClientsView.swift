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

    @State var selectedGatewayClient: String = ""
    @State var changeDefaultGatewayClient: Bool = false
    @State var addGatewayClient: Bool = false

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
                        GatewayClientCard(selectedGatewayClient: defaultGatewayClient!, disabled: true)
                            .padding(.top, 3)
                    }
                    .padding()
                }

                Button("Add Gateway Client", systemImage: "add") {
                    addGatewayClient = true
                }.buttonStyle(.relayButton(variant: .secondary))
                    .padding(.horizontal, 16).padding(
                        .bottom, 16
                    )
                    .sheet(
                        isPresented: $addGatewayClient,
                        onDismiss: {
                            addGatewayClient = false
                        },
                        content: {});

                        List(gatewayClients, id: \.self) { gatewayClient in
                            Button(action: {
                                selectedGatewayClient = gatewayClient.msisdn!
                                changeDefaultGatewayClient = true
                            }) {
                                GatewayClientCard(selectedGatewayClient: gatewayClient, disabled: false)
                                    .padding()
                            }
                        }
                        .confirmationDialog(
                            "Set as default gateway client?",
                            isPresented: $changeDefaultGatewayClient
                        ) {
                            Button("Make default") {
                                defaultGatewayClientMsisdn = selectedGatewayClient
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
        return gatewayClients.filter { $0.msisdn == defaultGatewayClientMsisdn }.first
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
