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

struct SecuritySettingsView: View {

    @State private var selected: UUID?
    @State private var deleteProcessing = false

    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false
    @State var showAlert: Bool = false
    @State var shouldTurnOffLocalTokenStorage: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
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

                                showAlert = true
                                alertTitle = "Success"
                                alertMessage =
                                    "Your platforms have been migrated to this device successfully!"
                            } catch {
                                showAlert = true
                                alertTitle = "Error"
                                alertMessage =
                                    "An error occurred while trying to migrate your platforms. Please try again later."
                                print(error)
                            }
                        } else {
                            // If user turns off token storage accounts
                            shouldTurnOffLocalTokenStorage = true
                            showAlert = true
                            alertTitle = "Beware"
                            alertMessage = "Turning this off will delete all tokens stored on this device and on the server. \nThis would revoke all accounts. You would have to add your accounts again."
                        }
                    }.alert(isPresented: $showAlert) {
                        if (shouldTurnOffLocalTokenStorage) {
                            // Show the revoking alert if you're turning off local storage of tokens
                            Alert(
                                title: Text(alertTitle),
                                message: Text(alertMessage),
                                primaryButton: .destructive(
                                    Text("Continue"),
                                    action: {
                                        revokeAllAccounts()
                                    }
                                ),
                                secondaryButton: .default(Text("Cancel")) {
                                    showAlert = false
                                    storePlatformsOnDevice = true
                                })
                        } else {
                            // Should the regular alert if turning on local storage of tokens
                            Alert(
                                title: Text(alertTitle),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK"), action: {
                                    do {
                                        dismiss()
                                    } catch {
                                    }
                                 
                                })
                            )
                        }
                        
                        
                      
                    }
                    .padding([.top], 12)
                    Text(String(localized:"This will store your platforms on this specific device, and migrate any existing platforms to this device. \nThis means you won't be able to access your platfoms if you lose this device"))
                    .font(RelayTypography.bodyMedium)
                    .foregroundStyle(RelayColors.colorScheme.onSurface.opacity(0.6)).padding([.bottom], 12)
                }.listRowSeparator(.hidden)

                Section(header: Text("Account")) {
                    Button("Log out") {
                        showIsLoggingOut.toggle()
                    }
                    .confirmationDialog("", isPresented: $showIsLoggingOut) {
                        Button("Log out", role: .destructive, action: logout)
                    } message: {
                        Text(String(localized:"You can log back in at anytime. All the messages sent would be deleted.", comment: "Explains that you can log into your account at any time, and all the messages sent would be deleted"))
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
                            Text(String(localized:"You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted", comment: "Explains that you can always create an account at a later date, but all previously stored tokens and platforms for your old account will be revoked and data deleted"))
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
                      ProgressView("Revoking...")//.foregroundStyle(Color.white)
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
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        print("Attempting to revoke accounts")
        
        let backgroundQueue = DispatchQueue(label: "revokeQueue", qos: .background)
        
        backgroundQueue.async {
            var success = true
            var errorMessage: String? = nil
            var entitiesToDelete: [StoredPlatformsEntity] = []
            
            do {
                let vault: Vault = Vault()
                let llt: String = try Vault.getLongLivedToken()
                let publisher = Publisher()
                
                let platformEntities = platforms
                
                // Loop through all platfoms
                for platform in platformEntities {
                    print("Revoking: \(String(describing: platform.name))...")
                    
                    // Filter sored accounts for current platform onlu
                    let matchingStoredPlatformsEntities = storedPlatforms.filter {storedPlatformEntity in
                        storedPlatformEntity.name == platform.name
                    }
                    
                    if matchingStoredPlatformsEntities.isEmpty {
                        print("No accounts for platform \(platform.name ?? "Unkown platform"), skipping")
                    } else {
                        for storedPlatformEntity in matchingStoredPlatformsEntities {
                            print("Attempting to revoke API token for account: \(storedPlatformEntity.account ?? "Unkown account") on platform: \(storedPlatformEntity.name ?? "Unkown platform")...")
                            
                            do {
                                let result: Bool = try publisher.revokePlatform(
                                    llt: llt, platform: platform.name!, account: storedPlatformEntity.account!, protocolType: platform.protocol_type!)
                                
                                if result {
                                    print("API revocation successful for \(storedPlatformEntity.account ?? "Unkown account"). Marking for local deletion")
                                    entitiesToDelete.append(storedPlatformEntity)
                                }
                                
                                else {
                                    print("API revocation failed for \(storedPlatformEntity.account ?? "Unkown account"). Server reported failure")
                                    success = false
                                    errorMessage = "Failed to revoke one or more accounts."
                                }
                            } catch {
                                print("Error during API revocation for \(storedPlatformEntity.account ?? "Unknown account"): \(error)")
                                errorMessage = "An error occurred during API communication."
                                success = false
                            }
                            
                        } // End loop
                    }
                }
                
                // Reset Database
                try DataController.resetDatabase(context: self.viewContext)
                var _ = try vault.refreshStoredTokens(llt: llt, context: self.viewContext)
                
                // Delete and refresh platforms
                viewContext.perform {
                    print("Performing Core Data deletion on main thread context")
                    
                    for platform in platforms {
                        self.viewContext.delete(platform)
                        print("Deleted platform entity: \(platform.name ?? "Unknown Platform")")
                    }
                    Publisher.refreshPlatforms(context: self.viewContext)
                    
                    do {
                        try self.viewContext.save()
                        print("Core Data context saved")
                    } catch {
                        print("Error saving Core Data context after revocation: \(error)")
                        errorMessage = "Failed to save local data: \(error.localizedDescription)"
                        success = false
                    }
                }
                isLoading = false
                self.alertTitle = "Success"
                self.alertMessage = "All selected accounts successfully revoked."
                self.showAlert = true
                self.shouldTurnOffLocalTokenStorage = false
                
           
                
            } catch {
                print("Unable to initiate revocation process: \(error)")
                          errorMessage = "An initial error occurred: \(error.localizedDescription)"
                          success = false // Mark overall process failure
                  DispatchQueue.main.async {
                      self.isLoading = false // Hide the spinner
                      self.alertTitle = "Error"
                      self.alertMessage = errorMessage ?? "An unknown error occurred."
                      self.showAlert = true
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
