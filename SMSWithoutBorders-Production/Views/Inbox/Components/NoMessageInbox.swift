//
//  NoMessageInbox.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct NoMessagesInbox: View {
    @Binding var pasteIncomingRequested: Bool

    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "tray")
                    .resizable()
                    .foregroundStyle(RelayColors.colorScheme.onSurface.opacity(0.2))
                    .frame(width: 150, height: 120)
                    .padding(.bottom, 7)

                Text("No messages in inbox")
                    .font(RelayTypography.headlineSmall)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RelayColors.colorScheme.primary)
                Spacer().frame(height: 10)
                Text("Your incoming messages would show up here once you paste them to get them decrypted.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundStyle(RelayColors.colorScheme.onSurface.opacity(0.7))
            }
            .padding()

            Spacer()

            VStack {
                Button {
                    pasteIncomingRequested.toggle()
                } label: {
                    Text("Paste new incoming message")
                }
                .buttonStyle(.relayButton(variant: .primary))
                .padding([.leading,.trailing], 16)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    @State var pasteIncomingMessage = false
    NoMessagesInbox(pasteIncomingRequested: $pasteIncomingMessage)
}
