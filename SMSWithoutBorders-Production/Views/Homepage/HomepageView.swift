//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

enum HomepageTabs {
    case recents
    case platforms
    case settings
    case gatewayClients
    case inbox
}

struct HomepageView: View {
    @Environment(\.managedObjectContext) var context

    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: PlatformsRequestedType = .available

    @State var composeNewMessageRequested: Bool = false
    @State var composeTextRequested: Bool = false
    @State var composeMessageRequested: Bool = false
    @State var composeEmailRequested: Bool = false

    @State var loginSheetRequested: Bool = false
    @State var createAccountSheetRequested: Bool = false
    @State var passwordRecoveryRequired: Bool = false
    @State var requestedPlatformName: String = ""

    @State var emailIsRequested = false
    @State var textIsRequested = false
    @State var messageIsRequested = false

    @State var requestedMessage: Messages?

    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationView {
            VStack {
                if requestedMessage != nil {
                    NavigationLink(
                        destination: EmailPlatformView(
                            message: requestedMessage!,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            emailComposeRequested: $composeEmailRequested,
                            requestedPlatformName: $requestedPlatformName
                        ),
                        isActive: $emailIsRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: TextPlatformView(
                            message: requestedMessage!,
                            textComposeRequested: $composeTextRequested,
                            requestPlatformName: $requestedPlatformName
                        ),
                        isActive: $textIsRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: MessagingView(
                            platformName: requestedMessage!.platformName,
                            message: requestedMessage!
                        ),
                        isActive: $messageIsRequested
                    ) {
                        EmptyView()
                    }
                }
                
                if requestedPlatformName.isEmpty == false || composeNewMessageRequested {
                    NavigationLink(
                    destination: EmailComposeView(
                        platformName: $requestedPlatformName,
                        isBridge: true,
                        message: $requestedMessage
                    ),
                    isActive: $composeNewMessageRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: EmailComposeView(
                            platformName: $requestedPlatformName,
                            message: $requestedMessage
                        ),
                        isActive: $composeEmailRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: TextComposeView(
                            platformName: $requestedPlatformName,
                            message: $requestedMessage
                        ),
                        isActive: $composeTextRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: MessagingView(
                            platformName: requestedPlatformName
                        ),
                        isActive: $composeMessageRequested
                    ) {
                        EmptyView()
                    }
                }
                
                else if createAccountSheetRequested || loginSheetRequested || passwordRecoveryRequired {
                    NavigationLink(
                        destination: SignupSheetView(
                            loginRequested: $loginSheetRequested,
                            accountCreated: $isLoggedIn
                        ),
                        isActive: $createAccountSheetRequested
                    ) {
                        EmptyView()
                    }

                    NavigationLink(
                        destination: LoginSheetView(
                            isLoggedIn: $isLoggedIn,
                            createAccountRequested: $createAccountSheetRequested,
                            passwordRecoveryRequired: $passwordRecoveryRequired
                        ),
                        isActive: $loginSheetRequested
                    ) {
                        EmptyView()
                    }
                    
                    NavigationLink(
                        destination:
                        RecoverySheetView(isRecovered: $isLoggedIn),
                        isActive: $passwordRecoveryRequired
                    ) {
                        EmptyView()
                    }
                }
                
                TabView(selection: Binding(
                    get: { selectedTab },
                    set: {
                        if $0 == .platforms && selectedTab != .platforms {
                            platformRequestType = .available
                        }
                        selectedTab = $0
                    }
                )) {
                    if (isLoggedIn) {
                        RecentsLoggedInView(
                            selectedTab: $selectedTab,
                            platformRequestType: $platformRequestType,
                            requestedMessage: $requestedMessage,
                            emailIsRequested: $emailIsRequested,
                            textIsRequested: $textIsRequested,
                            messageIsRequested: $messageIsRequested,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            composeTextRequested: $composeTextRequested,
                            composeMessageRequested: $composeMessageRequested,
                            composeEmailRequested: $composeEmailRequested,
                            requestedPlatformName: $requestedPlatformName
                        )
                        .tabItem() {
                            Image(systemName: "house.circle.fill")
                            Text("Recents")
                        }
                        .tag(HomepageTabs.recents)
                        .onAppear {
                            requestedMessage = nil
                            requestedPlatformName = ""
                        }

                        PlatformsView(
                            requestType: $platformRequestType,
                            requestedPlatformName: $requestedPlatformName,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            composeTextRequested: $composeTextRequested,
                            composeMessageRequested: $composeMessageRequested,
                            composeEmailRequested: $composeEmailRequested
                        )
                        .tabItem() {
                            Image(systemName: "apps.iphone")
                            Text("Platforms")
                        }
                        .tag(HomepageTabs.platforms)

                    } else {
                        RecentsNotLoggedInView(
                            isLoggedIn: $isLoggedIn,
                            composeNewMessageRequested: $composeNewMessageRequested,
                            createAccountSheetRequested: $createAccountSheetRequested,
                            loginSheetRequested: $loginSheetRequested,
                            requestedMessage: $requestedMessage,
                            emailIsRequested: $emailIsRequested
                        )
                        .tabItem() {
                            Image(systemName: "house.circle.fill")
                            Text("Get started")
                        }
                        .tag(HomepageTabs.recents)
                        .onAppear {
                            requestedMessage = nil
                            requestedPlatformName = ""
                        }

                    }

                    InboxView(
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested
                    )
                    .tabItem() {
                        Image(systemName: "tray")
                        Text("Inbox")
                    }
                    .tag(HomepageTabs.inbox)

                    GatewayClientsView()
                    .tabItem() {
                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        Text("Countries")
                    }
                    .tag(HomepageTabs.gatewayClients)


                    SettingsView(isLoggedIn: $isLoggedIn)
                    .tabItem() {
                        Image(systemName: "gear.circle.fill")
                        Text("Settings")
                    }
                    .tag(HomepageTabs.settings)
                }
                    
                
            }

        }
//        .onChange(of: isLoggedIn) { state in
//            if state {
//                Publisher.refreshPlatforms(context: context)
//            }
//        }
        .onAppear {
            do {
                isLoggedIn = try !Vault.getLongLivedToken().isEmpty
//                Task {
//                    if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
//                        print("Is searching for default....")
//                        do {
//                            try await GatewayClients.refresh(context: context)
//                        } catch {
//                            print("Error refreshing gateways: \(error)")
//                        }
//                    }
//                }
            } catch {
                print(error)
            }
        }
    }
}



// //// PREVIEWS //// //
struct HomepageView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = false

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return HomepageView(isLoggedIn: $isLoggedIn)
    }
}

struct HomepageViewInboxMessages_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = false

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return HomepageView(isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}

struct HomepageViewLoggedIn_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = true

    static var previews: some View {
        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return HomepageView(isLoggedIn: $isLoggedIn)
    }
}

struct HomepageViewLoggedInMessages_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""
    @State static var isLoggedIn: Bool = true

    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        UserDefaults.standard.register(defaults: [
            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: "+237123456782"
        ])

        return HomepageView(isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
