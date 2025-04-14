//
//  NoSentMessages.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct NoSentMessages: View {
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: PlatformsRequestedType

    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool

    @State var platformIsRequested = false

    var body: some View {
        VStack {
            Spacer()
            Spacer()

            VStack {
                Image("5")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 20)
                Text("Send your first message...")
                    .font(RelayTypography.titleLarge)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
//                    selectedTab = .platforms
                    platformRequestType = .compose
                    platformIsRequested.toggle()
                } label: {
                    Text("Send new message")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.relayButton(variant: .primary))
                .sheet(isPresented: $platformIsRequested) {
                    PlatformsView(
                        requestType: $platformRequestType,
                        requestedPlatformName: $requestedPlatformName,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        composeTextRequested: $composeTextRequested,
                        composeMessageRequested: $composeMessageRequested,
                        composeEmailRequested: $composeEmailRequested
                    ) {
                        platformIsRequested.toggle()
                    }
                }

                Button {
                    selectedTab = .platforms
                    platformRequestType = .available
                } label: {
                    Text("Save platforms")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.relayButton(variant: .secondary))

            }
            .padding()
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: PlatformsRequestedType = .available
    @State var requestedMessage: Messages? = nil
    @State var emailIsRequested: Bool = false
    @State var textIsRequested: Bool = false
    @State var messageIsRequested: Bool = false
    @State var composeNewMessagesIsRequested: Bool = false
    @State var requestedPlatformName = "gmail"

    NoSentMessages(
        selectedTab: $selectedTab,
        platformRequestType: $platformRequestType,
        requestedPlatformName: $requestedPlatformName,
        composeNewMessageRequested: $composeNewMessagesIsRequested,
        composeTextRequested: $textIsRequested,
        composeMessageRequested: $messageIsRequested,
        composeEmailRequested: $emailIsRequested
    )
}


