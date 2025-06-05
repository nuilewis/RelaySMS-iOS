//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData


@main
struct SMSWithoutBorders_ProductionApp: App {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var dataController: DataController

    @AppStorage(OnboardingView.ONBOARDING_COMPLETED)
    private var onboardingCompleted: Bool = false

    @State private var alreadyLoggedIn: Bool = false
    @State private var isLoggedIn: Bool = false
    
    // Initialize dependednces
    @StateObject var storedPlatformStore: StoredPlatformStore
    @StateObject var platformStore: PlatformStore
    
    init() {
        let initialDataController: DataController
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // RUNNING TESTS
            initialDataController = DataController(forTesting: true)
            //self._dataController = StateObject(wrappedValue: DataController(forTesting: true))
            print("Test initialization: Test launch. Initializing standard DataController." )
        } else {
            initialDataController = DataController()
            //self._dataController = StateObject(wrappedValue: DataController())
            print("App initialization: Normal launch. Initializing standard DataController." )
        }
        
        self._dataController = StateObject(wrappedValue: initialDataController)
        let viewContext = initialDataController.container.viewContext
        
        self._storedPlatformStore = StateObject(wrappedValue: StoredPlatformStore(context: viewContext))
        self._platformStore = StateObject(wrappedValue: PlatformStore(context:viewContext))
        
        print("All StateObjects dependencies initialized in App init.")
        
    }

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                Text("Running Unit Tests. Main UI suppressed.")
                                   .onAppear {
                                        print("Test UI WindowGroup appeared.")
                                   }
            } else {
                Group {
                    if(!onboardingCompleted) {
                        OnboardingView()
                            .environment(\.managedObjectContext, dataController.container.viewContext)
                            .environmentObject(platformStore)
                            .environmentObject(storedPlatformStore)
                            
                    }
                    else {
                        HomepageView(isLoggedIn: $isLoggedIn)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        .environmentObject(platformStore)
                        .environmentObject(storedPlatformStore)
                        .alert("You are being logged out!", isPresented: $alreadyLoggedIn) {
                            Button("Get me out!") {
                                getMeOut()
                            }
                        } message: {
                            Text(String(localized:"It seems you logged into another device. You can use RelaySMS on only one device at a time.", comment: "Explains that you cannot be logged in on multiple devices at a time"))
                        }
                        .onAppear() {
                            validateLLT()
                        }
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .active {
                                validateLLT()
                            }
                        }
                    }
                }
                .onAppear {
                    Publisher.refreshPlatforms(context: dataController.container.viewContext)

                    Task {
                        if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                            print("Is searching for default....")
                            do {
                                try await GatewayClients.refresh(context: dataController.container.viewContext)
                            } catch {
                                print("Error refreshing gateways: \(error)")
                            }
                        }
                    }
                }
            }
   
        }
    }

    func getMeOut() {
        logoutAccount(context: dataController.container.viewContext)
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print(error)
        }
    }

    func validateLLT() {
        print("Validating LLT for continuation...")
        DispatchQueue.background(background: {
            do {
                let vault = Vault()
                let llt = try Vault.getLongLivedToken()
                if llt.isEmpty{
                    return
                }

                let result = try vault.validateLLT(
                    llt: llt,
                    context: dataController.container.viewContext
                )
                if !result {
                    alreadyLoggedIn = true
                }
//                else {
//                    let vault = Vault()
//                    try vault.refreshStoredTokens(
//                        llt: llt,
//                        context: dataController.container.viewContext,
//                        storedTokenEntities: <#FetchedResults<StoredPlatformsEntity>#>
//                    )
//                }
            } catch {
                print(error)
            }
        }, completion: {

        })
    }

    func getIsLoggedIn() -> Bool {
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print("Failed to check if llt exist: \(error)")
        }
        return false
    }

}


