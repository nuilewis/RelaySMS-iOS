//
//  SelectedClientHeader.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 02/04/2025.
//

import SwiftUI
struct SelectedClientHeader: View {
    let client: GatewayClientsEntity?
    var body: some View {
        Group {
            if let defaultClient = client {
                VStack(alignment: .leading) {
                    Text("Selected Gateway client")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    // Use the simplified card, passing false for canEdit
                    GatewayClientCard(
                        clientEntity: defaultClient,
                        canEdit: false,
                        isSelected: true  // Visually mark as selected in the header
                    )
     
                }
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
            } else {
                // Optional: Show something if no default is selected or found
                Text("No default client selected.")
                //    .padding()
                // EmptyView()
            }
        }
    }
}
