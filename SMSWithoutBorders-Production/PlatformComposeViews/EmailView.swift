//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import MessageUI
import CryptoKit

struct EmailView: View {
    @Environment(\.managedObjectContext) var context
//    @Environment(\.dismiss) var dismiss
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""
    
    @AppStorage(SecuritySettingsView.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false

    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

    @State var composeTo: String = ""
    @State var composeFrom: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""
    
    @State private var encryptedFormattedContent: String = ""
    
    @State var isShowingMessages: Bool = false
    @State var isSendingRequest: Bool = false

    private var platformName: String
    private var fromAccount: String
    
    init(platformName: String, fromAccount: String) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        print("Searching platform: \(platformName)")

        self.fromAccount = fromAccount
    }
    
    
    var body: some View {

        NavigationView {
            VStack {
                VStack{
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
                
                VStack{
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
        .disabled(isSendingRequest)
        .padding()
        .navigationTitle("Compose email")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Send") {
                    isSendingRequest = true
                    let platform = platforms.first!
                    DispatchQueue.background(background: {
                        do {
                            let messageComposer = try Publisher.publish(platform: platform, context: context)
                            
                            var shortcode: UInt8? = nil
                            shortcode = platform.shortcode!.bytes[0]
                            
                            encryptedFormattedContent = try messageComposer.emailComposer(
                                platform_letter: shortcode!,
                                from: fromAccount,
                                to: composeTo,
                                cc: composeCC,
                                bcc: composeBCC,
                                subject: composeSubject,
                                body: composeBody)
                        } catch {
                            print("Some error occured while sending: \(error)")
                        }
                        isShowingMessages.toggle()
                        isSendingRequest = false
                    })
                }.sheet(isPresented: $isShowingMessages) {
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
            print("Yep cancelled")
            break
        case .failed:
            print("Damn... failed")
            break
        case .sent:
            print("Yep, all good")
            
            DispatchQueue.background(background: {
                var messageEntities = MessageEntity(context: context)
                messageEntities.id = UUID()
                messageEntities.platformName = platformName
                messageEntities.fromAccount = fromAccount
                messageEntities.toAccount = composeTo
                messageEntities.subject = composeSubject
                messageEntities.body = composeBody
                messageEntities.date = Int32(Date().timeIntervalSince1970)
                do {
                    try context.save()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
                
            })
            break
        @unknown default:
            print("Not even sure what this means")
            break
        }
    }
    
    func formatEmailForViewing(decryptedData: String) -> (platformLetter: String, to: String, cc: String, bcc: String, subject: String, body: String) {
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
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        @State var globalDimiss = false
        
        return EmailView(platformName: "gmail", 
                         fromAccount: "dev@relay.sms")
            .environment(\.managedObjectContext, container.viewContext)
    }
}
