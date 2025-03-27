//
//  GatewayClientCard.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct GatewayClientCard: View {
    var selectedGatewayClient: GatewayClientsEntity
    var disabled: Bool

    var body: some View {
        VStack {
            Group {
                Text(selectedGatewayClient.msisdn!)
                    .font(.headline)
                    .padding(.bottom, 5)
                    .foregroundColor(disabled ? .secondary : .primary )

                HStack {
                    Text(selectedGatewayClient.operatorName! + " -")
                    Text(selectedGatewayClient.operatorCode!)
                }
                .foregroundColor(.secondary)
                .font(.subheadline)

                Text(selectedGatewayClient.country!)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
