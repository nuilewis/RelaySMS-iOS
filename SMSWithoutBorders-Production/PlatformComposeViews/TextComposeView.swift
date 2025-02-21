//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import SwiftUI
import MessageUI

struct TextComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    @State var textBody: String = ""
    @State var placeHolder: String = "What's happening?"
    @State private var fromAccount: String = ""

    @State private var encryptedFormattedContent = ""
    @State private var isPosting: Bool = false
    @State private var isShowingMessages: Bool = false
    
    @State private var dismissRequested: Bool = false
    @State private var requestToChooseAccount: Bool = false

    @State var platform: PlatformsEntity?
    
    private var platformName: String

    init(platformName: String) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))

        print("Searching platform: \(platformName)")
    }

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    if self.textBody.isEmpty {
                        TextEditor(text: $placeHolder)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .disabled(true)
                                .padding()
                    }
                    TextEditor(text: $textBody)
                        .font(.body)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                }
            }
            .sheet(isPresented: $requestToChooseAccount) {
                AccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested
                ) {}
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
        }
        .navigationBarTitle("Compose Post")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    let platform = platforms.first!
                    isPosting = true
                    DispatchQueue.background(background: {
                        do {
                            let messageComposer = try Publisher.publish( context: context)
                            var shortcode: UInt8? = nil
                            shortcode = platform.shortcode!.bytes[0]
                            
                            encryptedFormattedContent = try messageComposer.textComposer(
                                platform_letter: shortcode!,
                                sender: fromAccount,
                                text: textBody)
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
                        completion: handleCompletion(_:))
                    .ignoresSafeArea()
                }
            }
        })
        
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
                messageEntities.subject = ""
                messageEntities.body = textBody
                messageEntities.date = Int32(Date().timeIntervalSince1970)
                
                do {
                    try context.save()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
                
            })
            break
        @unknown default:
            break
        }
    }
}

struct TextView_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var globalDismiss = false
        return TextComposeView(platformName: "twitter")
            .environment(\.managedObjectContext, container.viewContext)
    }
}
