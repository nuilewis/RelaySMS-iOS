//
//  ComposeNewMessage.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct ComposeNewMessageSheet: View {
    @Binding var composeNewMessageSheetRequested: Bool
    @Binding var parentSheetShown: Bool

    var body: some View {
        VStack {
            Spacer().frame(height:24)
            Image(systemName: "plus.message")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)

            Text("Message with RelaySMS account")
                .font(RelayTypography.titleMedium)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding()

            Text("You can send messages from RelaySMS at anytime. Your account details would be your phone number attached to our official domain.\n\nExample +123456789@relaysms.me")
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            Text("Replies would come back by SMS to the phone number associated with your account")
                .multilineTextAlignment(.center)
                .font(.footnote)

            Button(action: {
                parentSheetShown.toggle()
                composeNewMessageSheetRequested.toggle()
            }) {
                Text("Continue")
            }
            .buttonStyle(.relayButton(variant: .primary))
            .tint(.primary)
            .padding()
            
            Text("Emailing is the only currently supported protocol, we are working on including more soon")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.bottom, 10)

        }
        .padding([.leading, .trailing], 16)
    }
}
