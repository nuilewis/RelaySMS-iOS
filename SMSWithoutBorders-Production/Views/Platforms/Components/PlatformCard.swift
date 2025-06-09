//
//  PlatformCard.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 25/03/2025.
//

import CoreData
import SwiftUI

struct PlatformCard: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject private var storedPlatformStore: StoredPlatformStore

    @State var sheetIsPresented: Bool = false
    @State var isEnabled: Bool = false

    @Binding var composeNewMessageRequested: Bool
    @Binding var platformRequestType: PlatformsRequestedType
    @Binding var composeViewRequested: Bool
    @Binding var parentRefreshRequested: Bool
    @Binding var requestedPlatformName: String

    let platform: Platform?
    let serviceType: Publisher.ServiceTypes

    var callback: (() -> Void)?

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                        if platform != nil {
                            requestedPlatformName = platform!.name
                        }
                        sheetIsPresented.toggle()
                    }) {
                        VStack {
                            if let imageData = platform?.imageData {
                                Image(uiImage: UIImage(data: imageData)!)
                                    .resizable()
                                    .renderingMode(isEnabled ? .none : .template)
                                    .foregroundColor(isEnabled ? .clear : .gray)
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .padding()
                            } else {
                                Image("Logo")
                                    .resizable()
                                    .renderingMode(
                                        isEnabled ? .none : .template
                                    )
                                    .foregroundColor(isEnabled ? .clear : .gray)
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .padding()
                            }

                            Text(platform != nil ? (platform!.name) : "")
                                .font(.caption2)
                                .foregroundColor(isEnabled ? .primary : .gray)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(isEnabled ? .accentColor : .gray)
                    .sheet(isPresented: $sheetIsPresented) {
                        PlatformDetailsBottomsheet(
                            description: getServiceTypeDescriptions(
                                serviceType: serviceType
                            ),
                            composeDescription:
                                getServiceTypeComposeDescriptions(
                                    serviceType: serviceType
                                ),
                            platform: platform,
                            isEnabled: $isEnabled,
                            composeNewMessageRequested:
                                $composeNewMessageRequested,
                            platformRequestedType: $platformRequestType,
                            composeViewRequested: $composeViewRequested,
                            refreshParent: $parentRefreshRequested,
                            callback: callback

                        )
                        .applyPresentationDetentsIfAvailable(
                            canLarge: platform?.protocolType
                                == Publisher.ProtocolTypes.PNBA)
                    }
                }
                if isEnabled {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 50, y: -50)
                }
            }
        }
        .onAppear {
            isEnabled = platform != nil ? isStored(platform: platform!) : true
        }
    }

    func getServiceTypeDescriptions(serviceType: Publisher.ServiceTypes)
        -> String
    {
        switch serviceType {
        case .EMAIL:
            return Publisher.ServiceTypeDescriptions.EMAIL.localizedValue()
        case .MESSAGE:
            return Publisher.ServiceTypeDescriptions.MESSAGE.localizedValue()
        case .TEXT:
            return Publisher.ServiceTypeDescriptions.TEXT.localizedValue()
        case .BRIDGE:
            return Publisher.ServiceTypeDescriptions.BRIDGE.localizedValue()
        }
    }

    func getServiceTypeComposeDescriptions(serviceType: Publisher.ServiceTypes)
        -> String
    {
        switch serviceType {
        case .EMAIL:
            return Publisher.ServiceComposeTypeDescriptions.EMAIL
                .localizedValue()
        case .MESSAGE:
            return Publisher.ServiceComposeTypeDescriptions.MESSAGE
                .localizedValue()
        case .TEXT:
            return Publisher.ServiceComposeTypeDescriptions.TEXT
                .localizedValue()
        case .BRIDGE:
            return Publisher.ServiceComposeTypeDescriptions.BRIDGE
                .localizedValue()
        }
    }

    func isStored(platform: Platform) -> Bool {
        return storedPlatformStore.publishablePlatforms.contains(where: {
            print("is enabled from platform card: \($0.name == platform.name) ")
           return $0.name == platform.name
        })
    }

}
