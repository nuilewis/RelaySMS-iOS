//
//  GatewayClientCard.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import CoreData
import SwiftUI

///Old
//struct GatewayClientCard: View {
//    var clientEntity: GatewayClientsEntity
//    var disabled: Bool
//    @State var showSheet: Bool = false
//    @State var isSuccessful: Bool = false
//    @State var editGatewayClientSheetPresented: Bool = false
//    @Environment(\.managedObjectContext) var context
//
//    @State var canEdit: Bool = false
//
//
//    init(clientEntity: GatewayClientsEntity, disabled: Bool) {
//        self.clientEntity = clientEntity
//        self.disabled = disabled
//        let defaultGatewayClients: [GatewayClients] = GatewayClients.getDefaultGatewayClients()
//
//        var isDefaultClient = false
//
//        if let entityMsisdn = clientEntity.msisdn {
//            isDefaultClient = defaultGatewayClients.contains {
//                $0.msisdn == entityMsisdn
//            }
//            if entityMsisdn == "+15024439537" {
//                isDefaultClient = true
//            }
//        }
//
//
//        _canEdit = State(initialValue: !isDefaultClient)
//
//        print("Initializing GatewayClientCard for \(clientEntity.msisdn ?? "nil"). Is Default: \(isDefaultClient). Can Edit: \(!isDefaultClient)")
//    }
//
//
//    var body: some View {
//        VStack {
//            Group {
//                HStack {
//                    Text(clientEntity.msisdn ?? "N/A")
//                        .font(.headline)
//                        .padding(.bottom, 5)
//                        .foregroundColor(disabled ? .secondary : .primary)
//
//                    Spacer()
//                    if !canEdit {
//                        Image(systemName: "lock")
//                    }
//                }
//
//                HStack {
//                    Text(clientEntity.operatorName ?? "N/A" + " -")
//                    Text(clientEntity.operatorCode ?? "N/A")
//                }
//                .foregroundColor(.secondary)
//                .font(.subheadline)
//
//                Text(clientEntity.country ?? "N/A")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .contextMenu {
//                if canEdit {
//                    Button("Edit", systemImage: "pencil") {
//                        editGatewayClientSheetPresented = true
//                        // Edit gateway Client
//                    }
//                    Button("Delete", systemImage: "trash", role: .destructive) {
//                        do {
//                            try GatewayClients.deleteGatewayClient(context: context, client: GatewayClients.fromEntity(entity: clientEntity))
//                            showSheet = true
//                            isSuccessful = true
//                        } catch {
//                            print("Unable to delete GatewayClient")
//                            showSheet = false
//                        }
//
//                    }
//                }
//
//
//            }.alert(
//                isPresented: $showSheet,
//                content: {
//                    Alert(title: Text("Gateway Client Deleted"))
//                }
//            )
//            .sheet(
//                isPresented: $editGatewayClientSheetPresented,
//                onDismiss: {
//                    editGatewayClientSheetPresented = false
//                },
//                content: {
//                    AddEditGatewayClientForm(
//                        gatewayClient: GatewayClients.fromEntity(entity: clientEntity),
//                        isPresented: $editGatewayClientSheetPresented)
//                })
//
//
//        }
//    }
//}


struct GatewayClientCard: View {
    var clientEntity: GatewayClientsEntity
    //    var disabled: Bool
    var canEdit: Bool = false
    var isSelected: Bool


    var body: some View {
        VStack {
            Group {
                HStack {
                    Text(clientEntity.msisdn ?? "N/A")
                        .font(.headline)
                        .padding(.bottom, 5)
                    //.foregroundColor(disabled ? .secondary : .primary)

                    Spacer()
                    if !canEdit {
                        Image(systemName: "lock.fill").foregroundColor(RelayColors.colorScheme.onSurface.opacity(0.5))
                    }
                }

                HStack {
                    Text(clientEntity.operatorName ?? "N/A")
                    Text(clientEntity.operatorCode ?? "N/A")
                }
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(clientEntity.country ?? "N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

        }.padding()
            .background(isSelected ? RelayColors.colorScheme.primaryContainer : Color.clear).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

    }
}
