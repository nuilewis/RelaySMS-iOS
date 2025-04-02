//
//  GatewayClientCardListItem.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 02/04/2025.
//

import SwiftUI

struct GatewayClientCardListItem: View {
    @ObservedObject var client: GatewayClientsEntity

    let isSelected: Bool
    let canEdit: Bool

    let onSetDefault: () -> Void
    let onRequestEdit: () -> Void
    let onRequestDelete: () -> Void

    var body: some View {
        GatewayClientCard(
            clientEntity: client, canEdit: canEdit, isSelected: isSelected
        )
        .onTapGesture {
                if !isSelected {
                    onSetDefault()
                }
            }.contextMenu {
                Button("Set as Default", systemImage: "checkmark") {
                    onSetDefault()
                }
                if canEdit {
                    Button("Edit", systemImage: "pencil") {
                        onRequestEdit()
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onRequestDelete()
                    }
                }
            }
    }
}
