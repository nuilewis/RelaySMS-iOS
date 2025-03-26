//
//  SendFirstMessage.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct SendFirstMessage: View {
    @State private var sheetComposeNewPresented: Bool = false
    @Binding var composeNewSheetRequested: Bool

    var body: some View {
        VStack() {
            Image("5")
            Button {
                sheetComposeNewPresented.toggle()
            } label: {
                Label("Compose new message", systemImage: "pencil.circle")
            }
            .buttonStyle(.relayButton(variant: .primary))
            .sheet(isPresented: $sheetComposeNewPresented) {
                ComposeNewMessageSheet(
                    composeNewMessageSheetRequested: $sheetComposeNewPresented,
                    parentSheetShown: $composeNewSheetRequested)
                    .applyPresentationDetentsIfAvailable()
            }
            
            Spacer().frame(height: 16)
            
            Text("Your phone number is your primary account!")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("your_phonenumber@relaysms.me")
                .font(.caption2)
                .foregroundStyle(RelayColors.colorScheme.primary)
        }

    }
}
