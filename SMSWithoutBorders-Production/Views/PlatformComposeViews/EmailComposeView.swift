//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import CoreData
import CryptoKit
import MessageUI
import SwiftUI

struct EmailComposerView: View {
    @Binding var composeTo: String
    @Binding var composeFrom: String
    @Binding var composeCC: String
    @Binding var composeBCC: String
    @Binding var composeSubject: String
    @Binding var composeBody: String
    @Binding var fromAccount: String

    var isBridge: Bool

    var body: some View {
        VStack {
            if !isBridge {
                VStack {
                    HStack {
                        Text("From ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField(fromAccount, text: $composeFrom)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(true)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)

            }

            VStack {
                HStack {
                    Text("To ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeTo)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)

            VStack {
                HStack {
                    Text("Cc ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeCC)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)

            VStack {
                HStack {
                    Text("Bcc ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeBCC)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)

            VStack {
                HStack {
                    Text("Subject ")
                        .foregroundColor(Color.secondary)
                    Spacer()
                    TextField("", text: $composeSubject)
                }
                .padding(.leading)
                Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            Spacer(minLength: 9)

            VStack {
                TextEditor(text: $composeBody)
                    .accessibilityLabel("composeBody")
            }
        }

    }
}

struct EmailComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

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

    @AppStorage(SettingsKeys.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false

    @State private var encryptedFormattedContent: String = ""
    @State var isShowingMessages: Bool = false
    @State var isSendingRequest: Bool = false
    @State var requestToChooseAccount: Bool = false
    @State var composeFrom: String = ""
    @State var fromAccount: String = ""

    @State var dismissRequested = false

    private var isBridge: Bool = false

    @Binding var message: Messages?
    @Binding var platformName: String

    @State var composeTo: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading = false

    init(
        platformName: Binding<String>,
        isBridge: Bool = false,
        message: Binding<Messages?>
    ) {
        print("Requested platform name: \(platformName.wrappedValue )")
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "name == %@", platformName.wrappedValue))
        _message = message
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName.wrappedValue))

        _platformName = platformName
        self.isBridge = isBridge
    }

    var body: some View {
        NavigationView {
            VStack {
                EmailComposerView(
                    composeTo: $composeTo,
                    composeFrom: $composeFrom,
                    composeCC: $composeCC,
                    composeBCC: $composeBCC,
                    composeSubject: $composeSubject,
                    composeBody: $composeBody,
                    fromAccount: $fromAccount,
                    isBridge: isBridge
                )
                #if DEBUG
                    Button("Present missing token error alert") {
                        showAlert = true
                        alertTitle = "Tokens Missing"
                        alertMessage = "Your tokens have not been found on this device. Please revoke access to your account and log back in to continue."
                    }
                #endif
            }
            .padding()
            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested
                ) {
                    requestToChooseAccount.toggle()
                    if self.message != nil {
                        composeTo = self.message!.toAccount
                        composeCC = self.message!.cc
                        composeBCC = self.message!.bcc
                        composeSubject = self.message!.subject
                        composeBody = self.message!.data
                    }
                }
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
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
            if isBridge {
                if self.message != nil {
                    composeTo = self.message!.toAccount
                    composeCC = self.message!.cc
                    composeBCC = self.message!.bcc
                    composeSubject = self.message!.subject
                    composeBody = self.message!.data
                }
            }
        }
        .navigationTitle("Compose email")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSendingRequest {
                    ProgressView()
                } else {
                    Button("Send") {
                        isSendingRequest = true
                        //                    let platform = platforms.first!
                        DispatchQueue.background(background: {
                            do {
                                encryptedFormattedContent =
                                    try getEncryptedContent(
                                        isBridge: self.isBridge)
                            } catch {
                                print(
                                    "Some error occured while sending: \(error)"
                                )
                            }
                            isShowingMessages.toggle()
                            isSendingRequest = false
                        })
                    }
                    .disabled(!isBridge && fromAccount.isEmpty)
                    .sheet(isPresented: $isShowingMessages) {
                        SMSComposeMessageUIView(
                            recipients: [defaultGatewayClientMsisdn],
                            body: $encryptedFormattedContent,
                            completion: handleCompletion(_:)
                        )
                        .ignoresSafeArea()
                    }
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
                        isLoading.toggle()
                        print("Atrempting to revoke account")
                        let backgroundQueue = DispatchQueue(label: "revokeAccountQueue", qos: .background)

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
                                        context.delete(entityToDelete)
                                    }

                                    let result: Bool =
                                        try publisher.revokePlatform(
                                            llt: llt,
                                            platform: unwrappedPlatform.name!,
                                            account: fromAccount,
                                            protocolType: unwrappedPlatform.protocol_type!
                                        )

                                    if result {
                                        DispatchQueue.main.async {
                                            do {
                                                let llt = try Vault.getLongLivedToken()
                                                var _ = try vault.refreshStoredTokens(llt: llt, context: context)

                                                try context.save()
                                                print( "Successfully revoked platform")
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

                    }),
                secondaryButton: .default(Text("Cancel")) {
                    showAlert.toggle()
                })
        }.overlay {
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

    func getEncryptedContent(isBridge: Bool = false) throws -> String {
        if !isBridge {
            let messageComposer = try Publisher.publish(context: context)
            let shortcode: UInt8 = "g".data(using: .utf8)!.first!

            let tokenManager = StoredTokensEntityManager(context: context)
            // Get the stored platform and use the tokens if the platform tokens exist
            let storedPlatformEntity = storedPlatforms.first {
                $0.account == fromAccount
            }  // Gets the speciic account that matches the currently selected fromAccount
            var tokensExists: Bool = false
            var storedTokenForPlatform: StoredToken?

            if let entity = storedPlatformEntity, entity.isStoredOnDevice {
                print(
                    "Platform is stored on device.. Will use saved tokens for publishing if tokens are available"
                )
                tokensExists = tokenManager.storedTokenExists(
                    forPlarform: entity.id ?? "")

                // Get tokens if they exist
                if tokensExists {
                    storedTokenForPlatform = tokenManager.getStoredToken(
                        forPlatform: entity.id!)
                }

                // Trigger a refresh if tokens are lost
                if !tokensExists && entity.isStoredOnDevice {
                    // TODO: Alert the user to revoke the platform or something.
                }
            } else {
                print("Platform is not stored on device")
            }

            return try messageComposer.emailComposer(
                platform_letter: shortcode,
                from: fromAccount,
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                accessToken: tokensExists
                    ? storedTokenForPlatform?.accessToken : nil,
                refreshToken: tokensExists
                    ? storedTokenForPlatform?.refreshToken : nil
            )
        } else {
            let (cipherText, clientPublicKey) = try Bridges.compose(
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                context: context
            )
            if try !Vault.getLongLivedToken().isEmpty {
                return try Bridges.payloadOnly(
                    context: context, cipherText: cipherText)!
            } else {
                return try Bridges.authRequestAndPayload(
                    context: context,
                    cipherText: cipherText,
                    clientPublicKey: clientPublicKey!
                )!
            }
        }
    }

    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Yep cancelled")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .failed:
            print("Yep failed")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .sent:
            saveMessageEntity()
            dismiss()
            break
        @unknown default:
            print("Not even sure what this means")
            break
        }
    }

    private func saveMessageEntity() {
        DispatchQueue.background(background: {
            var messageEntities = MessageEntity(context: context)
            messageEntities.id = UUID()
            messageEntities.platformName = platformName
            messageEntities.fromAccount = fromAccount
            messageEntities.toAccount = composeTo
            messageEntities.cc = composeCC
            messageEntities.bcc = composeBCC
            messageEntities.subject = composeSubject
            messageEntities.body = composeBody
            messageEntities.date = Int32(Date().timeIntervalSince1970)

            if isBridge {
                messageEntities.type = Bridges.SERVICE_NAME
            }

            DispatchQueue.main.async {
                do {
                    try context.save()
                    dismiss()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
            }
        })
    }

    func formatEmailForViewing(decryptedData: String) -> (
        platformLetter: String, to: String, cc: String, bcc: String,
        subject: String, body: String
    ) {
        let splitString = decryptedData.components(separatedBy: ":")

        let platformLetter: String = splitString[0]
        let to: String = splitString[1]
        let cc: String = splitString[2]
        let bcc: String = splitString[3]
        let subject: String = splitString[4]
        let body: String = splitString[5]

        return (platformLetter, to, cc, bcc, subject, body)
    }
}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        @State var message: Messages? = Messages(
            id: UUID(),
            subject: "Test subject",
            data: "Test body",
            fromAccount: "from@test.com",
            toAccount: "to@test.com",
            platformName: "test platform",
            date: 0
        )

        @State var platformName = ""
        return EmailComposeView(
            platformName: $platformName, message: $message
        )
    }
}

struct EmailCompose_Preview: PreviewProvider {
    static var previews: some View {
        @State var composeTo: String = ""
        @State var composeFrom: String = ""
        @State var composeCC: String = ""
        @State var composeBCC: String = ""
        @State var composeSubject: String = ""
        @State var composeBody: String = ""
        @State var fromAccount: String = ""

        return EmailComposerView(
            composeTo: $composeTo,
            composeFrom: $composeFrom,
            composeCC: $composeCC,
            composeBCC: $composeBCC,
            composeSubject: $composeSubject,
            composeBody: $composeBody,
            fromAccount: $fromAccount,
            isBridge: false
        )
    }
}
