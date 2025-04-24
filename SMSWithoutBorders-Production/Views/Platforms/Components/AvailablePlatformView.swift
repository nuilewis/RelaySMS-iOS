//
//  AvailablePlatformView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 25/03/2025.
//

import SwiftUI

struct AvailablePlatformView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    @Binding var platformRequestedType: PlatformsRequestedType
    @Binding var phoneNumberAuthenticationRequested: Bool
    @Binding var parentIsEnabled: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var accountSheetRequested: Bool
    @Binding var composeViewRequested: Bool
    @Binding var loading: Bool
    @Binding var codeVerifier: String

    var platform: PlatformsEntity?
    var callback: (() -> Void)?
    var description: String
    var composeDescription: String

    var body: some View {
        VStack(alignment:.center) {
            Spacer()

            (platform != nil && platform!.image != nil ?
             Image(uiImage: UIImage(data: platform!.image!)!) : Image("Logo")
            )
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .padding()

            if platformRequestedType == .compose {
                Text(composeDescription)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .padding()
            } else {
                Text(description)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding()
            }

            Spacer().frame(maxHeight: 120)
            if phoneNumberAuthenticationRequested {
                PhoneNumberSheetView(
                    completed: $parentIsEnabled,
                    platformName: platform!.name!
                )
            }
            else {
                Button {
                    if(platform != nil) {
                        if platformRequestedType == .compose {
                            composeViewRequested.toggle()
                            dismiss()
                        }
                        else {
                            triggerPlatformRequest(platform: platform!)
                        }
                    } else {
                        composeNewMessageRequested.toggle()
                        dismiss()
                        callback?()
                    }
                } label: {
                    if platform == nil || platformRequestedType == .compose {
                        Text("Send new message")
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Add Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.relayButton(variant: .primary))
                .padding([.leading, .trailing], 16)
                .padding([.bottom], 24)

                if platform != nil && platformRequestedType == .available && parentIsEnabled {
                    Button("Remove Accounts", role: .destructive) {
                        accountSheetRequested = true
                    }
                }
            }
        }
    }

    private func triggerPlatformRequest(platform: PlatformsEntity) {
        let backgroundQueueu = DispatchQueue(label: "addingNewPlatformQueue", qos: .background)

        switch platform.protocol_type {
        case Publisher.ProtocolTypes.OAUTH2.rawValue:
            loading = true
            backgroundQueueu.async {
                do {
                    let publisher = Publisher()
                    let response = try publisher.getOAuthURL(
                        platform: platform.name!,
                        supportsUrlSchemes: platform.support_url_scheme)
                    codeVerifier = response.codeVerifier
                    openURL(URL(string: response.authorizationURL)!)
                }
                catch {
                    print("Some error occured: \(error)")
                }
            }
        case Publisher.ProtocolTypes.PNBA.rawValue:
            phoneNumberAuthenticationRequested = true
        case .none:
            Task {}
        case .some(_):
            Task {}
        }
    }
}

#Preview {
    var platform: PlatformsEntity? = nil
    @State var platformRequestedType: PlatformsRequestedType = .available
    var description: String = ""
    var composeDescription: String = ""
    @State var phoneNumberAuthenticationRequested: Bool = false
    @State var parentIsEnabled: Bool = false
    @State var composeNewMessageRequested: Bool = false
    var callback: (() -> Void)?
    @State var accountSheetRequested: Bool = false
    @State var composeViewRequested: Bool = false
    @State var loading: Bool = false
    @State var codeVerifier: String = ""
    @State var storePlatfomOnDevice: Bool = false

    AvailablePlatformView(
        platformRequestedType: $platformRequestedType,
        phoneNumberAuthenticationRequested: $phoneNumberAuthenticationRequested,
        parentIsEnabled: $parentIsEnabled,
        composeNewMessageRequested: $composeNewMessageRequested,
        accountSheetRequested: $accountSheetRequested,
        composeViewRequested: $composeViewRequested,
        loading: $loading,
        codeVerifier: $codeVerifier,
        platform: platform,
        callback: callback,
        description: description,
        composeDescription: composeDescription

    )
}
