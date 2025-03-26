//
//  SecuritySettingsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct SecuritySettingsView: View {
    public static var SETTINGS_MESSAGE_WITH_PHONENUMBER = "SETTINGS_MESSAGE_WITH_PHONENUMBER"
    @State private var selected: UUID?
    @State private var deleteProcessing = false
    
    @State private var isShowingRevoke = false
    @State var showIsLoggingOut: Bool = false
    @State var showIsDeleting: Bool = false

    @Binding var isLoggedIn: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section(header: Text("Account")) {
                    Button("Log out") {
                        showIsLoggingOut.toggle()
                    }.confirmationDialog("", isPresented: $showIsLoggingOut) {
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
