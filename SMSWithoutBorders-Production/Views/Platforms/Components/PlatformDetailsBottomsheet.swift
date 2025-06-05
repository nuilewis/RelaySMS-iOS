//
//  PlatformDetailsBottomsheet.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 25/03/2025.
//

import SwiftUI
import CoreData

struct PlatformDetailsBottomsheet: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    var description: String
    var composeDescription: String

    @State var loading = false
    @State var isRevoking = false
    @State var savingNewPlatform = false
    @State var failed: Bool = false
    @State var phoneNumberAuthenticationRequested: Bool = false
    @State var sheetComposeNewPresented = false
    @State var accountSheetRequested = false
    @State var revokeConfirmSheetRequested = false

    @State var errorMessage: String = ""

    //var platform: PlatformsEntity?
    var platform: Platform?
    
    @EnvironmentObject private var storedPlatformStore: StoredPlatformStore
    @EnvironmentObject private var platformStore: PlatformStore
    
    
    @AppStorage(Publisher.PLATFORM_CODE_VERIFIER)
    var codeVerifier: String = ""
    
    @State private var fromAccount: String = ""

    @Binding var parentIsEnabled: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var platformRequestedType: PlatformsRequestedType
    @Binding var composeViewRequested: Bool
    @Binding var refreshParent: Bool
    @State var storePlatformOnDevice: Bool = false

    var callback: (() -> Void)?

    init(
        description: String,
        composeDescription: String,
       // platform: PlatformsEntity?,
        platform: Platform?,
        isEnabled: Binding<Bool>,
        composeNewMessageRequested: Binding<Bool>,
        platformRequestedType: Binding<PlatformsRequestedType>,
        composeViewRequested: Binding<Bool>,
        refreshParent: Binding<Bool>,
        callback: (() -> Void)? = {}
    ) {
        self.description = description
        self.composeDescription = composeDescription
        self.platform = platform
        _parentIsEnabled = isEnabled
        _composeNewMessageRequested = composeNewMessageRequested
        _platformRequestedType = platformRequestedType
        _composeViewRequested = composeViewRequested
        _refreshParent = refreshParent
        self.callback = callback

        

    }

    var body: some View {
        VStack {
            if (isRevoking || loading) && platform != nil {
                SaveRevokePlatform(
                    name: platform!.name,
                    isSaving: $savingNewPlatform,
                    isRevoking: $isRevoking
                )
            }
            else if accountSheetRequested && platform != nil {
                SelectAccountSheetView(
                    filter: platform!.name,
                    fromAccount: $fromAccount,
                    dismissParent: $parentIsEnabled
                ) {
                    revokeConfirmSheetRequested.toggle()
                }
                .confirmationDialog(String("Revoke?"), isPresented: $revokeConfirmSheetRequested) {
                    Button("Revoke", role: .destructive) {
                        isRevoking = true
//                        accountSheetRequested = false

                        let backgroundQueueu = DispatchQueue(label: "revokeAccountQueue", qos: .background)
                        backgroundQueueu.async {
                            do {
                                let llt = try Vault.getLongLivedToken()
                                let publisher = Publisher()
                                let response = try publisher.revokePlatform(
                                    llt: llt,
                                    platform: platform!.name,
                                    account: fromAccount,
                                    protocolType: platform!.protocolType.rawValue                                )
                                
                                // Delete token for the account beign revoked
                                print("Searching for token for the platform for: \(platform!.name.localizedCapitalized) beign revoked to delete")
                                for storedEntity in storedPlatformStore.storedPlatforms{
                                    if storedEntity.name  == platform!.name {
                                        storedPlatformStore.deleteStoredPlatform(byId: storedEntity.id)
                                    }
                                }
                              
                                if response {
                                    let vault = Vault()
                                    do {
                                        let llt = try Vault.getLongLivedToken()
                                        try vault.refreshStoredTokens(
                                            llt: llt,
                                            context: context,
                                            storedPlatformStore: storedPlatformStore
                                        )
                                    } catch {
                                        print(error)
                                    }
                                }

                                DispatchQueue.main.async {
                                    isRevoking = false
                                    refreshParent.toggle()
                                    dismiss()
                                }
                            } catch {
                                print("Error revoking: \(error)")
                            }
                        }
                    }
                } message: {
                    Text(String(localized: "Revoking removes the ability to send messages from this account. You can store the account again at anytime.", comment: "Sats that revoking a social platform will remove yout ability to send messages to that platform from your account, but you can always add the account again at anytime"))
                }
            }
            else {
                AvailablePlatformView(
                    platformRequestedType: $platformRequestedType,
                    phoneNumberAuthenticationRequested: $phoneNumberAuthenticationRequested,
                    parentIsEnabled: $parentIsEnabled,
                    composeNewMessageRequested: $composeNewMessageRequested,
                    accountSheetRequested: $accountSheetRequested,
                    composeViewRequested: $composeViewRequested,
                    loading: $loading,
                    platform: platform,
                    callback: callback,
                    description: description,
                    composeDescription: composeDescription
                )
            }
        }
        .onOpenURL { url in
            print("Received new url: \(url)")
            DispatchQueue.background(background: {
                savingNewPlatform = true
                do {
                    if !codeVerifier.isEmpty {
                        print("Platofmr code verifier is available")
                        try Publisher.processIncomingUrls(
                            context: context,
                            url: url,
                            codeVerifier: codeVerifier,
                            storeOnDevice: storePlatformOnDevice,
                            storedPlatformStore: storedPlatformStore
                        )
                        parentIsEnabled = true
               
                        codeVerifier = "" // Important!! - Set the code verifier back to empty so we do not keep stale code verifiers
                        print("Removed stale code verifier")
                    }
                    else {
                        failed = true
                        errorMessage = "An error occured please try again later: Missing code verifier"
                    }
             
                    dismiss()
                } catch {
                    print(error)
                    failed = true
                    errorMessage = error.localizedDescription
                }
            }, completion: {
                loading = false
            })
        }
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
    }


}


struct PlatformDetailsBottomsheet_Preview: PreviewProvider {
    static var previews: some View {
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        var description: String = String(localized:"Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book", comment: "Explains some history about lorem Impsum")
        var composeDescription: String = String(localized:"[Compose] Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book", comment: "Explains some history about Lorem Ipsum")
        
        @State var saveRequested = false
        @State var codeVerifier: String = ""
        @State var isEnabled: Bool = false
        @State var composeNewMessage: Bool = false
        @State var composeViewRequested: Bool = false
        @State var platformRequestedType: PlatformsRequestedType = .available

        return PlatformDetailsBottomsheet(
            description: description,
            composeDescription: composeDescription,
            platform: nil,
            isEnabled: $isEnabled,
            composeNewMessageRequested: $composeNewMessage,
            platformRequestedType: $platformRequestedType,
            composeViewRequested: $composeViewRequested,
            refreshParent: $isEnabled
        )
    }
}
