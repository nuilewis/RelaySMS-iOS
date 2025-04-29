//
//  SecuritySettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct SettingsKeys {
    public static let SETTINGS_MESSAGE_WITH_PHONENUMBER: String =
        "SETTINGS_MESSAGE_WITH_PHONENUMBER"
    public static let SETTINGS_STORE_PLATFORMS_ON_DEVICE: String =
        "SETTINGS_STORE_PLATFORMS_ON_DEVICE"
}

enum SecurityAlertType {
   case migrationStatus
   case revocationConfirmation
   case revocationStatus
}

struct SecuritySettingsView: View {

    @State private var selected: UUID?
    @State private var deleteProcessing = false

    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false
    
    @State var showAlert: Bool = false
    @State var activeAlertType: SecurityAlertType? = nil
    @State var migrationSuccessful: Bool = false
    @State var revokingSuccessful: Bool = false
    @State private var isLoading = false

    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    private var storePlatformsOnDevice: Bool = false

    @Binding var isLoggedIn: Bool

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms:
        FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms:
        FetchedResults<PlatformsEntity>

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section(header: Text("Security")) {
                    Toggle(
                        "Store platforms on this device",
                        isOn: $storePlatformsOnDevice
                    ).onChange(of: storePlatformsOnDevice) { newValue in

                        if newValue {
                            // Trigger a refresh
                            let vault = Vault()
                            do {
                                let llt: String = try Vault.getLongLivedToken()
                                vault.migratePlatformsToDevice(
                                    llt: llt, context: viewContext)

                                activeAlertType = .migrationStatus
                                showAlert = true
                                migrationSuccessful = true
                            } catch {
                                activeAlertType = .migrationStatus
                                showAlert = true
                                migrationSuccessful = false
                                print("Migration error: \(error)")
                            }
                        } else {
                            // If user turns off token storage accounts
                            activeAlertType = .revocationConfirmation
                            showAlert = true
                        }
                    }.alert(isPresented: $showAlert) {
                        switch activeAlertType {
                        case .migrationStatus:
                            return    Alert(
                                title: Text(migrationSuccessful ? "Success" : "Error"),
                                message: Text(
                                    migrationSuccessful
                                        ? "Your platforms have been migrated to this device successfully!"
                                        : "An error occurred while trying to migrate your platforms. Please try again later."
                                ),
                                dismissButton: .default(
                                    Text("OK"),
                                    action: {
                                        dismiss()
                                    })
                            )
                 
                        case .revocationConfirmation:
                            return    Alert(
                                title: Text("Beware"),
                                message: Text("Turning this off will delete all tokens stored on this device and on the server. \nThis would revoke all accounts. You would have to add your accounts again."
                                ),
                                primaryButton: .destructive(
                                    Text("Continue"),
                                    action: {
                                        revokeAllAccounts()
                                    }
                                ),
                                secondaryButton: .default(Text("Cancel")) {
                                    showAlert = false
                                    activeAlertType = .revocationConfirmation
                                    storePlatformsOnDevice = true
                                    dismiss()
                                }
                            )
                   
                        case .revocationStatus:
                            return   Alert(
                                title: Text(
                                    revokingSuccessful ? "Success" : "Error"),
                                message: Text(revokingSuccessful ?  "All accounts successfully revoked." : "Unable to automatically revoke your accounts, please try doing it manually"),
                                dismissButton: .default(
                                    Text("OK"),
                                    action: {
                                        dismiss()
                                    })
                            )
           
                        case nil:
                          return Alert(
                                title: Text("Dummy Alert"),
                                message: Text("Dummy Alert"),
                                dismissButton: .default(
                                    Text("OK"),
                                    action: {
                                        dismiss()
                                    })
                            )
                        
                        }
                    }.padding([.top], 12)
                    Text(String(localized: "This will store your platforms on this specific device, and migrate any existing platforms to this device. \nThis means you won't be able to access your platfoms if you lose this device"
                        )
                    )
                    .font(RelayTypography.bodyMedium)
                    .foregroundStyle(
                        RelayColors.colorScheme.onSurface.opacity(0.6)
                    ).padding([.bottom], 12)
                }.listRowSeparator(.hidden)

                Section(header: Text("Account")) {
                    Button("Log out") {
                        showIsLoggingOut.toggle()
                    }
                    .confirmationDialog("", isPresented: $showIsLoggingOut) {
                        Button("Log out", role: .destructive, action: logout)
                    } message: {
                        Text(
                            String(
                                localized: "You can log back in at anytime. All the messages sent would be deleted.",
                                comment: "Explains that you can log into your account at any time, and all the messages sent would be deleted"
                            ))
                    }
                    .disabled(!isLoggedIn)

                    if deleteProcessing {
                        ProgressView()
                    } else {
                        Button("Delete Account", role: .destructive) {
                            showIsDeleting.toggle()
                        }.confirmationDialog("", isPresented: $showIsDeleting) {
                            Button(
                                "Continue Deleting", role: .destructive,
                                action: deleteAccount)
                        } message: {
                            Text(
                                String(localized:"You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted",
                                    comment: "Explains that you can always create an account at a later date, but all previously stored tokens and platforms for your old account will be revoked and data deleted"
                                ))
                        }
                        .disabled(!isLoggedIn)
                    }
                }.listRowSeparator(.hidden)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black
                        .opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Revoking...")  //.foregroundStyle(Color.white)
                        .padding()
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }

    func logout() {
        logoutAccount(context: viewContext)
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print(error)
        }
        dismiss()
    }

    func deleteAccount() {
        deleteProcessing = true
        DispatchQueue.background(
            background: {
                do {
                    let llt = try Vault.getLongLivedToken()
                    try Vault.completeDeleteEntity(
                        context: viewContext,
                        longLiveToken: llt,
                        storedTokenEntities: storedPlatforms,
                        platforms: platforms)
                } catch {
                    print("Error deleting: \(error)")
                }
                deleteProcessing = false
            },
            completion: {
                DispatchQueue.main.async {
                    logoutAccount(context: viewContext)
                    do {
                        isLoggedIn = try !Vault.getLongLivedToken().isEmpty
                    } catch {
                        print(error)
                    }
                    dismiss()
                }
            })
    }
    
    func revokeAllAccounts() {
        
        //1. Set isLoading to true
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        print("Attempting to revoke accounts...")
        
        
        //2. Start a background queue thread
        let backgroundQueue = DispatchQueue(label: "revokeQueue", qos: .background)
        
        
        //3. Execute revocation logic
        backgroundQueue.async {
            
            var overallRevokeSuccessful = true
            var finalErrorMessage: String?
            let vault: Vault = Vault()
            let publisher: Publisher = Publisher()
            var llt: String = ""
            
            var platformData: [(name: String, protocolType: String)] = []
            var storedPlatformData: [(name: String, account: String)] = []
            
            
            viewContext.performAndWait {
                platformData = platforms.compactMap{ p in
                    guard let name = p.name, let type = p.protocol_type else { return nil }
                    return (name: name, protocolType: type)
                }
                
                storedPlatformData = storedPlatforms.compactMap{ sp in
                    guard let name = sp.name, let account = sp.account else { return nil }
                    return (name: name, account: account)
                }
            }
            
            
            // Main revocation logic
            do {
                
                llt = try Vault.getLongLivedToken()
                
                // Loop through platforms
                for platformInfo in platformData {
                    print("Processing platform: \(platformInfo.name)...")
                    
                    
                    // Filter stored accounts for the current platform
                    let matchingStoredAccounts = storedPlatformData.filter {
                        $0.name == platformInfo.name
                    }
                    
                    if matchingStoredAccounts.isEmpty {
                        print("No accounts for platform \(platformInfo.name), skipping revocation.")
                        continue // Skip to next platform
                    }
                    
                    // Loop through accounts for this platform
                    for accountInfo in matchingStoredAccounts {
                        print("Attempting to revoke API token for account: \(accountInfo.account) on platform: \(platformInfo.name)...")
                        
                        do {
                            let apiRevokeSuccess: Bool = try publisher.revokePlatform(
                                llt: llt,
                                platform: platformInfo.name,
                                account:  accountInfo.account,
                                protocolType: platformInfo.protocolType
                            )
                            
                            if apiRevokeSuccess {
                                print("API revocation successful for \(accountInfo.account).")
                           // Reset the whole database if all API calls success
                            } else {
                                print("API revocation failed for \(accountInfo.account) on platform \(platformInfo.name). Server reported failure.")
                                finalErrorMessage = finalErrorMessage ?? "Failed to revoke one or more accounts via API." // Keep the first error
                                overallRevokeSuccessful = false
                                
                                // break - Enable break if we want to stop at the first failure
                            }
                        } catch {
                            print("Error during API revocation for \(accountInfo.account): \(error)")
                            finalErrorMessage = finalErrorMessage ?? "An error occurred during API communication." // Keep the first error
                            overallRevokeSuccessful = false
                            
                            // break - Enable break if we want to stop at the first failure

                        }
                    }
                    
                    
                }
                
                // Post revocation Database cleanup if all calls succeeded
                
                if (overallRevokeSuccessful) {
                    print("All API revocations successful (or no accounts found). Resetting local data...")
                
                    // Perform Core Data reset and refresh platforms on apprporiate queue
                    var coreDataError: Error?
                    
                    viewContext.performAndWait {
                        do {
                            try DataController.resetDatabase(context: viewContext)
                            print("Databse rest.")
                            
                            // Delete Platforms because reseting the Database doesnt delete the platfoms
                            for platform in platforms {
                                self.viewContext.delete(platform)
                                print(
                                    "Deleted platform entity: \(platform.name ?? "Unknown Platform")"
                                )
                            }
                            
                            // Then call Refresh platforms
                            Publisher.refreshPlatforms(context: viewContext)
                            print("Refreshed platforms")
                            
                            // Save context
                            try viewContext.save()
                            print("Core Data conext saved after reset/refresh")
                            
                            var _ = try vault.refreshStoredTokens(llt: llt, context: viewContext)
                        } catch {
                            print("Error during Core Data reset/save: \(error)")
                            coreDataError = error
                        }
                    }
                    
                    // If Core Data failed, mark overall process as failed
                    
                    if let error = coreDataError {
                        overallRevokeSuccessful = false
                        finalErrorMessage = finalErrorMessage ?? "Failed to update local data after revocation: \(error.localizedDescription)"
                        
                    } else {
                        print("Local data reset and refreshed successfully")
                    }
                    
                }
                
                else {
                    print("Skipping local data reset due to API revocation failures")
                }
                
            } catch {
                print("Unable to initiate revocation process: \(error)")
                finalErrorMessage = finalErrorMessage ?? "An initial error occurred: \(error.localizedDescription)"
                 overallRevokeSuccessful = false
            }
            
            
            // 4. Dispactch back to the main thread to update UI state
            
            DispatchQueue.main.async {
                self.showAlert = true
                self.activeAlertType = .revocationStatus
                self.isLoading = false
                self.revokingSuccessful = overallRevokeSuccessful
                
                if !overallRevokeSuccessful {
                    print("Revovation process failed, Reverting 'Store Platforms on device' toggel")
                    self.storePlatformsOnDevice = true
                } else {
                    print("Revocation process completed successfully.")
                }
            }
            
        }
        
        
    }
}

struct SecuritySettingsView_Preview: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
        @State var isLoggedIn = true
        SecuritySettingsView(isLoggedIn: $isLoggedIn)
    }
}
