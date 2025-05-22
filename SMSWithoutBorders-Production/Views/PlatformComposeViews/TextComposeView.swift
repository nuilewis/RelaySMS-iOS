//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import MessageUI
import SwiftUI

struct TextComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode

    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    #if DEBUG
        private var defaultGatewayClientMsisdn: String =
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]
                == "1"
            ? ""
            : UserDefaults.standard.object(
                forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String
                ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif

    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    private var isPlatformsStoredOnDevice: Bool = false

    @State var textBody: String = ""
    @State var placeHolder: String = "What's happening?"
    @State private var fromAccount: String = ""

    @State private var encryptedFormattedContent = ""
    @State private var isPosting: Bool = false
    @State private var isShowingMessages: Bool = false

    @State private var dismissRequested: Bool = false
    @State private var requestToChooseAccount: Bool = false

    @State var platform: PlatformsEntity?

    @Binding var message: Messages?
    @Binding var platformName: String

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading = false

    init(platformName: Binding<String>, message: Binding<Messages?>) {
        _platformName = platformName
        _message = message
        let platformNameWrapped = platformName.wrappedValue
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformNameWrapped))

        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformNameWrapped))

        print("Searching platform: \(platformNameWrapped)")
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("From account: \(fromAccount)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                #if DEBUG
                    Button("Present missing token error alert") {
                        showAlert = true
                        alertTitle = "Missing Tokens"
                        alertMessage = "Your tokens have not been found on this device. Please revoke access to your account and log back in to continue."
                    }
                #endif

                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .disabled(true)
                    }
                    TextEditor(text: $textBody)
                        .font(.body)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .padding()
            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested,
                    isSendingMessage: true
                ) {
                    requestToChooseAccount.toggle()

                    if self.message != nil {
                        textBody = self.message!.data
                    }
                }
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
            .navigationBarTitle("Compose Post")
        }
        .onChange(of: dismissRequested) { state in
            if state {
                dismiss()
            }
        }
        .task {
            if storedPlatforms.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    let platform = platforms.first!
                    isPosting = true
                    DispatchQueue.background(background: {
                        do {
                            let messageComposer = try Publisher.publish(context: context)
                            let tokenManager = StoredTokensEntityManager(context: context)
                            var shortcode: UInt8? = nil
                            shortcode = platform.shortcode!.bytes[0]

                            // Get the stored platform and use the tokens if the platform tokens exist
                            let storedPlatformEntity = storedPlatforms.first {
                                $0.account == fromAccount
                            }  // Gets the speciic account that matches the currently selected `fromAccount`
                            var tokensExists: Bool = false
                            var storedTokenForPlatform: StoredToken?

                            if let entity = storedPlatformEntity, !entity.access_token!.isEmpty {
                                tokensExists = tokenManager.storedTokenExists(forPlarform: entity.id ?? "")

                                // Get tokens if they exist
                                if tokensExists {
                                    storedTokenForPlatform = tokenManager.getStoredToken(forPlatform: entity.id!)
                                }
                            } else {
                                print("Platform is not stored on device")
                            }

                            encryptedFormattedContent =
                                try messageComposer.textComposerV1(
                                    platform_letter: shortcode!,
                                    sender: fromAccount,
                                    text: textBody,
                                    accessToken: tokensExists
                                        ? storedTokenForPlatform?.accessToken
                                        : nil,
                                    refreshToken: tokensExists
                                        ? storedTokenForPlatform?.refreshToken
                                        : nil
                                )

                            print("Transmitting to sms app: \(encryptedFormattedContent)")

                            isPosting = false
                            isShowingMessages.toggle()
                        } catch {
                            print("Some error occured while sending: \(error)")
                        }
                    })
                }
                .disabled(isPosting || fromAccount.isEmpty)
                .sheet(isPresented: $isShowingMessages) {
                    SMSComposeMessageUIView(
                        recipients: [defaultGatewayClientMsisdn],
                        body: $encryptedFormattedContent,
                        completion: handleCompletion(_:)
                    )
                    .ignoresSafeArea()
                }
            }
        })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .destructive(
                    Text("Revoke Account"),
                    action: {
                        revokeAccount()
                    }),
                secondaryButton: .default(Text("Cancel")){
                    showAlert.toggle()
                })
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
    }

    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            break
        case .failed:
            break
        case .sent:
            DispatchQueue.background(background: {
                var messageEntities = MessageEntity(context: context)
                messageEntities.id = UUID()
                messageEntities.platformName = platformName
                messageEntities.fromAccount = fromAccount
                messageEntities.toAccount = ""
                messageEntities.subject = fromAccount
                messageEntities.body = textBody
                messageEntities.date = Int32(Date().timeIntervalSince1970)

                DispatchQueue.main.async {
                    do {
                        try context.save()
                        dismiss()
                    } catch {
                        print("Failed to save message entity: \(error)")
                    }
                }
            })
            break
        @unknown default:
            break
        }
    }
    
    func revokeAccount(){
        isLoading.toggle()
        print("Atrempting to revoke account")
        let backgroundQueue = DispatchQueue( label: "revokeAccountQueue", qos: .background)
        backgroundQueue.async {
            do {
                let vault: Vault = Vault()
                let llt: String = try Vault.getLongLivedToken()
                let publisher = Publisher()

                let platformEntity = platforms.first {
                    $0.name == platformName
                }

                if let unwrappedPlatform = platformEntity {
                    print("platform is: \(unwrappedPlatform)")
                    print("Triggered revoking method")
                    let storedPlatformEntityToDelete = storedPlatforms.first {
                        $0.account == fromAccount
                    }
                    if let entityToDelete = storedPlatformEntityToDelete {
                        StoredTokensEntityManager(context: context).deleteStoredTokenById(forPlatform: entityToDelete.id!)
                        context.delete(entityToDelete)
                    }
                   

                    let result: Bool =
                        try publisher.revokePlatform(
                            llt: llt,
                            platform: unwrappedPlatform.name!,
                            account: fromAccount,
                            protocolType:unwrappedPlatform.protocol_type!
                        )

                    if result {
                        DispatchQueue.main.async {
                            do {
                                let llt = try Vault.getLongLivedToken()
                                try vault.refreshStoredTokens(
                                    llt: llt,
                                    context: context,
                                    storedTokenEntities: storedPlatforms
                                )
                     
                                try context.save()
                                print("Successfully revoked platform")
                                dismiss()
                    
                            } catch {
                                print(error)
                            }
                        }
                    }
                } else {
                    print(
                        "Platform is null, so cant revoke"
                    )
                }
            } catch {
                print(
                    "Unable to revoke platform: \(error)"
                )
            }
        }
    }
}

struct TextView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        @State var message: Messages? = Messages(
            id: UUID(),
            subject: "Hello world",
            data:"The scroll view displays its content within the scrollable content region. As the user performs platform-appropriate scroll gestures, the scroll view adjusts what portion of the underlying content is visible. ScrollView can scroll horizontally, vertically, or both, but does not provide zooming functionality.",
            fromAccount: "@afkanerd",
            toAccount: "toAccount@gmail.com",
            platformName: "twitter",
            date: Int(Date().timeIntervalSince1970))

        @State var globalDismiss = false
        @State var platformName = "twitter"
        return TextComposeView(platformName: $platformName, message: $message)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
