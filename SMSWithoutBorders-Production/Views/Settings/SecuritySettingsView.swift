//
//  SecuritySettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI


struct SettingsKeys {
    public static let SETTINGS_MESSAGE_WITH_PHONENUMBER: String = "SETTINGS_MESSAGE_WITH_PHONENUMBER"
    public static let SETTINGS_STORE_PLATFORMS_ON_DEVICE: String = "SETTINGS_STORE_PLATFORMS_ON_DEVICE"
}


struct SecuritySettingsView: View {

    @State private var selected: UUID?
    @State private var deleteProcessing = false
    
    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false
    @State var showAlert: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    
    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    private var storePlatformsOnDevice: Bool = false

    @Binding var isLoggedIn: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section(header: Text("Security")) {
                    Toggle("Store platforms on this device", isOn: $storePlatformsOnDevice).onChange(of: storePlatformsOnDevice) { newValue in
                        
                        if newValue {
                            // Trigger a refresh
                            let vault = Vault()
                            do {
                                let llt: String = try Vault.getLongLivedToken()
                                vault.migratePlatformsToDevice(llt: llt, context: viewContext)
                                
                                showAlert = true
                                alertTitle = "Success"
                                alertMessage = "Your platforms have been migrated to this device successfully!"
                            } catch {
                                showAlert = true
                                alertTitle = "Error"
                                alertMessage = "An error occurred while trying to migrate your platforms. Please try again later."
                                print(error)
                            }
                        }
                        
                        //TODO: I think you should revoke the platforms if this is set to false so the user can add them again let them be added to the vault
                        
                        if !newValue {
                            //TODO: Revoke platfomrs and clear accounts here
                        }
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
                            Button("Continue Deleting", role: .destructive, action: deleteAccount)
                        } message: {
                            Text(String(localized:"You can create another account anytime. All your stored tokens would be revoked from the Vault and all data deleted", comment: "Explains that you can always create an account at a later date, but all previously stored tokens and platforms for your old account will be revoked and data deleted"))
                        }
                        .disabled(!isLoggedIn)
                    }
                }.listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    func configureDefaults() {
        let storePlatformOnDevice: Bool? = UserDefaults.standard.bool(forKey: SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
        if storePlatformOnDevice == nil {
            UserDefaults.standard.register(defaults: [
                SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE: false
            ])
        }
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
        DispatchQueue.background(background: {
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
        }, completion: {
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
