//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import CoreData
import SwiftUI

enum PlatformsRequestedType: CaseIterable {
    case available
    case compose
    case revoke
}

struct PlatformsView: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject private var storedPlatformStore: StoredPlatformStore
    @EnvironmentObject private var platformStore: PlatformStore

    @State private var id = UUID()
    @State private var refreshRequested = false
    @State private var hasAppeared = false

    @Binding var requestType: PlatformsRequestedType
    @Binding var requestedPlatformName: String
    @Binding var composeNewMessageRequested: Bool
    @Binding var composeTextRequested: Bool
    @Binding var composeMessageRequested: Bool
    @Binding var composeEmailRequested: Bool

    var callback: (() -> Void)?

    let columns = [
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10),
    ]

    init(
        requestType: Binding<PlatformsRequestedType>,
        requestedPlatformName: Binding<String>,
        composeNewMessageRequested: Binding<Bool>,
        composeTextRequested: Binding<Bool>,
        composeMessageRequested: Binding<Bool>,
        composeEmailRequested: Binding<Bool>,
        callback: (() -> Void)? = nil
    ) {
        self._requestType = requestType
        self._requestedPlatformName = requestedPlatformName
        self._composeNewMessageRequested = composeNewMessageRequested
        self._composeTextRequested = composeTextRequested
        self._composeMessageRequested = composeMessageRequested
        self._composeEmailRequested = composeEmailRequested
        self.callback = callback
}

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Use your RelaySMS account")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)

                    PlatformCard(
                        isEnabled: true,
                        composeNewMessageRequested: $composeNewMessageRequested,
                        platformRequestType: $requestType,
                        composeViewRequested: getBindingComposeVariable(
                            type: "email"),
                        parentRefreshRequested: $refreshRequested,
                        requestedPlatformName: $requestedPlatformName,
                        platform: nil,
                        serviceType: Publisher.ServiceTypes.BRIDGE,
                        callback: callback
                    ).padding(.bottom, 32)

                    HStack {
                        Text("Use your online accounts")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                    }

//                    #if DEBUG
//                        Button("Refresh") {
//                            platformStore.refresh()
//                        }
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                    #endif

                    if platformStore.isLoading {
                        ProgressView("Loading Platforms...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let errorMessage = platformStore.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else if platformStore.platforms.isEmpty {
                        Text("No online platforms saved yet...")
                        Button("Load Platforms") {
                            Publisher.refreshPlatforms(context: context)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    } else {
                        LazyVGrid(
                            columns: columns, alignment: .leading, spacing: 20
                        ) {
                            if requestType == .compose {
                                ForEach(filterForStoredPlatforms(), id: \.name)
                                { item in
                                    createPlatformCard(for: item)
                                }
                            } else {
                                ForEach(platformStore.platforms, id: \.name) {
                                    item in
                                    createPlatformCard(for: item)
                                }
                            }
                        }
                    }

                }
                .id(id)
                .onChange(of: refreshRequested) { refresh in
                    if refresh {
                        print("refreshing....")
                        id = UUID()
                        platformStore.refresh()
                    }
                }

                VStack(alignment: .center) {
                    Button {
                        requestType =
                            requestType == .compose ? .available : .compose
                    } label: {
                        if requestType == .compose {
                            Text("Save more platforms...")
                        } else {
                            Text("Send new message...")
                        }
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle(getRequestTypeText(type: requestType))
            .padding(16)
        }.onAppear {
            if !hasAppeared {
                hasAppeared = true
                        print("[PlatformsView - onAppear]: View appeared for the first time")
                        if platformStore.platforms.count == 0 {
                            print("[PlatformsView - onAppear]: No platforms found, refreshing....")
                            Publisher.refreshPlatforms(context: context)
                        }
                    }
        }
        .task {
            print("[Platforms View]: Number of platforms: \(platformStore.platforms.count)")
        }
    }

    private func createPlatformCard(for item: Platform) -> some View {
        let serviceType = item.serviceType.rawValue
        let composeBinding = getBindingComposeVariable(type: serviceType)
        let platformServiceType = getServiceType(type: serviceType)
        
        // Check if paltform is publishable
        var isEnabled: Bool = false
   
        let storedPlatform = storedPlatformStore.publishablePlatforms.first {
            $0.name == item.name
        }
        if let storedAccount = storedPlatform {
            isEnabled = true
            print("create platform card, is platform enabled: \(isEnabled)")
        }
    

        return PlatformCard(
            isEnabled: isEnabled,
            composeNewMessageRequested: $composeNewMessageRequested,
            platformRequestType: $requestType,
            composeViewRequested: composeBinding,
            parentRefreshRequested: $refreshRequested,
            requestedPlatformName: $requestedPlatformName,
            platform: item,
            serviceType: platformServiceType,
            callback: callback
        )
    }

    func filterForStoredPlatforms() -> [Platform] {
        var _storedPlatforms: [Platform] = []

        for platform in platformStore.platforms {
            if storedPlatformStore.publishablePlatforms.contains(where: { $0.name == platform.name }) {
                _storedPlatforms.append(platform)
            }
        }
        return _storedPlatforms
    }

    func getBindingComposeVariable(type: String) -> Binding<Bool> {
        @State var defaultNil: Bool? = false
        switch type {
        case Publisher.ServiceTypes.EMAIL.rawValue:
            return $composeEmailRequested
        case Publisher.ServiceTypes.MESSAGE.rawValue:
            return $composeMessageRequested
        case Publisher.ServiceTypes.TEXT.rawValue:
            return $composeTextRequested
        default:
            return $composeEmailRequested
        }
    }

    func getRequestTypeText(type: PlatformsRequestedType) -> String {
        switch type {
        case .compose:
            return String(localized: "Send a message")
        case .revoke:
            return String(localized: "Remove a platform")
        default:
            return String(localized: "Available Platforms")
        }
    }

    func getServiceType(type: String) -> Publisher.ServiceTypes {
        switch type {
        case Publisher.ServiceTypes.EMAIL.rawValue:
            return Publisher.ServiceTypes.EMAIL
        case Publisher.ServiceTypes.MESSAGE.rawValue:
            return Publisher.ServiceTypes.MESSAGE
        case Publisher.ServiceTypes.TEXT.rawValue:
            return Publisher.ServiceTypes.TEXT

        default:
            return Publisher.ServiceTypes.BRIDGE
        }
    }

}

struct Platforms_Preview: PreviewProvider {
    static var previews: some View {

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        @State var requestedFromAccount: String? = "example@gmail.com"
        @State var requestedPlatformName: String = "gmail"

        @State var platformRequestType: PlatformsRequestedType = .available
        @State var composeNewMessage: Bool = false
        @State var composeTextRequested: Bool = false
        @State var composeMessageRequested: Bool = false
        @State var composeEmailRequested: Bool = false
        return PlatformsView(
            requestType: $platformRequestType,
            requestedPlatformName: $requestedPlatformName,
            composeNewMessageRequested: $composeNewMessage,
            composeTextRequested: $composeTextRequested,
            composeMessageRequested: $composeMessageRequested,
            composeEmailRequested: $composeEmailRequested
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}

//struct PlatformsCompose_Preview: PreviewProvider {
//    static var previews: some View {
//
//        let container = createInMemoryPersistentContainer()
//        populateMockData(container: container)
//
//        @State var requestedPlatformName: String = "gmail"
//        @State var platformRequestType: PlatformsRequestedType = .compose
//        @State var composeNewMessage: Bool = false
//        @State var composeTextRequested: Bool = false
//        @State var composeMessageRequested: Bool = false
//        @State var composeEmailRequested: Bool = false
//        @State var requestedFromAccount: String? = "example@gmail.com"
//        return PlatformsView(
//            requestType: $platformRequestType,
//            requestedPlatformName: $requestedPlatformName,
//            composeNewMessageRequested: $composeNewMessage,
//            composeTextRequested: $composeTextRequested,
//            composeMessageRequested: $composeMessageRequested,
//            composeEmailRequested: $composeEmailRequested
//        )
//            .environment(\.managedObjectContext, container.viewContext)
//    }
//}
