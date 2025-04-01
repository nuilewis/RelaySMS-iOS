//
//  GatewayClientCard.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct GatewayClientCard: View {
    var clientEntity: GatewayClientsEntity
    var disabled: Bool
    @State var showSheet: Bool = false
    @State var isSuccessful: Bool = false
    @State var editGatewayClientSheetPresented: Bool = false
    @Environment(\.managedObjectContext) var context

    var body: some View {
        VStack {
            Group {
                Text(clientEntity.msisdn ?? "N/A")
                    .font(.headline)
                    .padding(.bottom, 5)
                    .foregroundColor(disabled ? .secondary : .primary)

                HStack {
                    Text(clientEntity.operatorName ?? "N/A" + " -")
                    Text(clientEntity.operatorCode ?? "N/A")
                }
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(clientEntity.country ?? "N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contextMenu {
                Button("Edit", systemImage: "pencil") {
                    editGatewayClientSheetPresented = true
                    // Edit gateway Client
                }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    do {
                        try GatewayClients.deleteGatewayClient(context: context, client: GatewayClients.fromEntity(entity: clientEntity))
                        showSheet = true
                        isSuccessful = true
                    } catch {
                        print("Unable to delete GatewayClient")
                        showSheet = false
                    }

                }
    
            }.alert(
                isPresented: $showSheet,
                content: {
                    Alert(title: Text("Gateway Client Deleted"))
                })
            .sheet(
                isPresented: $editGatewayClientSheetPresented,
                onDismiss: {
                    editGatewayClientSheetPresented = false
                },
                content: {
                    AddEditGatewayClientForm(
                        gatewayClient: GatewayClients.fromEntity(entity: clientEntity),
                        isPresented: $editGatewayClientSheetPresented)
                })
        }
    }
}
