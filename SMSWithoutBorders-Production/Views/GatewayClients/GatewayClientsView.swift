//
//  GatewayClientsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 08/08/2024.
//

import SwiftUI

//struct GatewayClientsView: View {
//    @Environment(\.managedObjectContext) var context
//    @FetchRequest(sortDescriptors: [
//        NSSortDescriptor(
//            key: "msisdn",
//            ascending: true)
//    ]
//    ) var gatewayClients: FetchedResults<GatewayClientsEntity>
//
//    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
//    private var defaultGatewayClientMsisdn: String = ""
//
//    @State var selectedGatewayClientMsisdn: String = ""
//    @State var changeDefaultGatewayClient: Bool = false
//    @State var addGatewayClientSheetPresented: Bool = false
//    @State var showDeletedNotification: Bool = false
//    @State var isSuccessful: Bool = false
//
//    @State var defaultGatewayClient: GatewayClientsEntity?
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                if defaultGatewayClient != nil {
//                    VStack {
//                        Text("Selected Gateway client")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .font(.caption2)
//                            .padding(.bottom, 3)
//                            .foregroundColor(.secondary)
//                        GatewayClientCard(clientEntity: defaultGatewayClient!, disabled: true)
//                            .padding(.top, 3)
//                    }
//                    .padding()
//                }
//
//                Button("Add Gateway Client", systemImage: "add") {
//                    addGatewayClientSheetPresented = true
//                }.buttonStyle(.relayButton(variant: .secondary))
//                    .padding(.horizontal, 16).padding(
//                        .bottom, 16
//                    )
//                    .sheet(
//                        isPresented: $addGatewayClientSheetPresented,
//                        onDismiss: {
//                            addGatewayClientSheetPresented = false
//                        },
//                        content: {
//                            AddEditGatewayClientForm(isPresented: $addGatewayClientSheetPresented)
//                        })
//
//                List(gatewayClients, id: \.self) { gatewayClient in
//                    Button(action: {
//                        if let msisdn = gatewayClient.msisdn {
//                            selectedGatewayClientMsisdn = msisdn
//                            changeDefaultGatewayClient = true
//                        } else {
//                            print("No MSISDN found, MSISDN is nil")
//                            //TODO: Maybe show an alert or something
//                        }
//
//
//
//
//                    }) {
//                        GatewayClientCard(clientEntity: gatewayClient, disabled: false)
//                            .padding()
//                    }
//                }
//                .confirmationDialog(
//                    "Set as default gateway client?",
//                    isPresented: $changeDefaultGatewayClient
//                ) {
//                    Button("Make default") {
//                        defaultGatewayClientMsisdn = selectedGatewayClientMsisdn
//                    }
//                } message: {
//                    Text(String(localized: "Choosing a Gateway client in the same Geographical location as you helps improves the reliability of your messages being delivered", comment: "Explains that selecting a Gateway clinet int he same geographical localtiion helps improve the reliability of yout messages"))
//                }
//            }
//            .navigationTitle("Countries")
//        }
//        .onChange(of: defaultGatewayClientMsisdn) { state in
//            defaultGatewayClient = getDefaultGatewayClient()
//        }
//        .onAppear {
//            if !defaultGatewayClientMsisdn.isEmpty {
//                defaultGatewayClient = getDefaultGatewayClient()
//            }
//        }
//    }
//
//    func getDefaultGatewayClient() -> GatewayClientsEntity? {
//        gatewayClients.filter {
//            $0.msisdn == defaultGatewayClientMsisdn
//        }
//        .first
//    }
//}
//
//struct GatewayClientsView_Previoew: PreviewProvider {
//    static var previews: some View {
//        let container = createInMemoryPersistentContainer()
//        populateMockData(container: container)
//
//        UserDefaults.standard.register(defaults: [
//            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
//        ])
//
//        return GatewayClientsView()
//            .environment(\.managedObjectContext, container.viewContext)
//    }
//}


// NEW VIEW

struct GatewayClientsView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                key: "msisdn",
                ascending: true)
        ],
        animation: .default
    ) var gatewayClients: FetchedResults<GatewayClientsEntity>

    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State private var clientToEdit: GatewayClientsEntity? = nil
    @State private var clientToSetAsDefault: GatewayClientsEntity? = nil
    @State private var clientToDelete: GatewayClientsEntity? = nil


    // State for Alerts/Sheets
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var showDefaultClientChangeConfirm = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAddSheet = false
    @State private var showResultAlert = false

    @State private var listVersion = UUID()


    // Computed property for the currently selected default client entity
    private var selectedDefaultGatewayClient: GatewayClientsEntity? {
        gatewayClients.first { $0.msisdn == defaultGatewayClientMsisdn }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Display Selected Client Header
                SelectedClientHeader(client: selectedDefaultGatewayClient)

                Button("Add Gateway Client", systemImage: "plus.circle") {
                    showAddSheet = true
                }.buttonStyle(.relayButton(variant: .secondary))
                    .padding(.horizontal, 16).padding(
                        .bottom, 16
                    )

                GatewayClientList(
                    gatewayClients: gatewayClients,  // Pass the fetched results
                    defaultGatewayClientMsisdn: defaultGatewayClientMsisdn,  // Pass the default ID
                    onSetDefault: { client in  // Closure implementations

                        self.showDefaultClientChangeConfirm = true
                        self.clientToSetAsDefault = client

                    },
                    onRequestEdit: { client in  // Closure implementations
                        self.clientToEdit = client
                        self.showEditSheet = true
                    },
                    onRequestDelete: { client in  // Closure implementations
                        self.clientToDelete = client
                        self.showDeleteConfirm = true
                    },
                    onDeleteSwipe: { indexSet in  // Closure implementations
                        self.requestDelete(at: indexSet)
                    }
                ).id(listVersion)

            }.navigationTitle("Countries")
                .sheet(isPresented: $showAddSheet) {
                    AddEditGatewayClientForm(
                        isPresented: $showAddSheet,
                        defaultMsisdnStorage: $defaultGatewayClientMsisdn
                    ).environment(\.managedObjectContext, context)  // Endusre context is passed
                }
                .sheet(
                    item: $clientToEdit,
                    onDismiss: {
                        print("Edit sheet dismissed, updating list veriosn")
                        listVersion = UUID()
                    }
                ) { client in
                    AddEditGatewayClientForm(
                        gatewayClient: GatewayClients.fromEntity(entity: client),
                        isPresented: $showEditSheet,
                        defaultMsisdnStorage: $defaultGatewayClientMsisdn
                    ).environment(\.managedObjectContext, context)  // Endusre context is passed
                }
                .confirmationDialog("Delete Client?", isPresented: $showDeleteConfirm, presenting: clientToDelete) {
                    client in
                    Button("Delete \(client.msisdn ?? "Client")", role: .destructive) {
                        performDelete(client: client)
                    }
                    Button("Cancel", role: .cancel) {
                        clientToDelete = nil
                    }
                } message: {
                    client in
                    Text("Are you sure you want to delete the gateway client \(client.msisdn ?? "")? This cannot be undone.")
                        .alert(alertTitle, isPresented: $showResultAlert) {
                            Button("OK") { showResultAlert = false }
                        } message: {
                            Text(alertMessage)
                        }
                }
                .confirmationDialog(
                    "Set as default gateway client?",
                    isPresented: $showDefaultClientChangeConfirm
                ) {
                    if let clientToMakeDefault = clientToSetAsDefault {
                        Button("Make default") {
                            setDefaultClient(clientToMakeDefault)
                        }
                    }

                } message: {
                    Text(String(localized: "Choosing a Gateway client in the same Geographical location as you helps improves the reliability of your messages being delivered", comment: "Explains that selecting a Gateway clinet int he same geographical localtiion helps improve the reliability of yout messages"))
                }

        }
    }
    // Helper functions
    func setDefaultClient(_ client: GatewayClientsEntity) {
        if let msisdn = client.msisdn {
            defaultGatewayClientMsisdn = msisdn
            print("Set default client to: \(msisdn)")
        }
        clientToSetAsDefault = nil
    }

    // Handles swipe to delete request
    func requestDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            clientToDelete = gatewayClients[index]

            if clientToDelete?.isDefaultClient() == true {
                alertTitle = "Deletion Failed"
                alertMessage = "Cannot delete a built-in default gateway client."
                showResultAlert = true
                clientToDelete = nil
            } else {
                showDeleteConfirm = true
            }
        }
    }


    func performDelete(client: GatewayClientsEntity) {
        // Prevent deleting the currently selected default

        if client.msisdn == defaultGatewayClientMsisdn {
            alertTitle = "Deletion Failed"
            alertMessage = "Cannot delet the currently selected default gateway client"
            showResultAlert = true
            clientToDelete = nil
            return
        }

        // Prevent deleting default clients

        if client.isDefaultClient() {
            alertTitle = "Deletion Failed"
            alertMessage = "Cannot delete a default gateway client."
            showResultAlert = true
            clientToDelete = nil
            return
        }

        do {
            let clientValueType = GatewayClients.fromEntity(entity: client)

            try GatewayClients.deleteGatewayClient(context: context, client: clientValueType)

            alertTitle = "Deleted"
            alertMessage = "Successfully deleted client \(client.msisdn ?? "")."
            showResultAlert = true
        } catch {
            print("Error deleting client: \(error)")
            // Failure feedback
            alertTitle = "Error"
            alertMessage = "Failed to delete client \(client.msisdn ?? ""). \(error.localizedDescription)"
            showResultAlert = true
        }
        clientToDelete = nil
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


