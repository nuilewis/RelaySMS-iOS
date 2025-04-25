//
//  MessengerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 12/22/22.
//

import SwiftUI
import MessageUI
import CryptoKit
import ContactsUI
import Combine

struct TextInputField: View {
    let placeHolder: String
    @Binding var textValue: String
    @State var endIcon: Image?
    @State var function: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeHolder)
                .foregroundColor(Color(.placeholderText))
                .offset(y: textValue.isEmpty ? 0 : -25)
                .scaleEffect(textValue.isEmpty ? 1: 0.8, anchor: .leading)
            TextField("", text: $textValue)
        }
        .padding(.top, textValue.isEmpty ? 0 : 15)
        .frame(height: 52)
        .padding(.horizontal, 16)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1).foregroundColor(.secondary))
        .overlay(alignment: .trailing) {
            if endIcon != nil {
                Button {
                    function()
                } label: {
                    endIcon!
                        .resizable()
                        .frame(width: 30.0, height: 30.0)
                }
                .padding()
            }
        }
        .animation(.default)
    }
}

struct FieldMultiEntryTextDynamic: View {
    var text: Binding<String>
    
    var body: some View {
        TextEditor(text: text)
            .padding(.vertical, -8)
            .padding(.horizontal, -4)
            .frame(minHeight: 0, maxHeight: 150)
            .font(.custom("HelveticaNeue", size: 17, relativeTo: .headline))
            .foregroundColor(.primary)
            .dynamicTypeSize(.medium ... .xxLarge)
            .fixedSize(horizontal: false, vertical: true)
    } // End Var Body
} // End Struct


struct MessagingView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest var messages: FetchedResults<MessageEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

    #if DEBUG
    private var defaultGatewayClientMsisdn: String =
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? "" : UserDefaults.standard.object(forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif
    
    @FocusState private var isFocused: Bool
    @StateObject private var coordinator = Coordinator()
    
    @State var platform: PlatformsEntity?
    @State var messageBody :String = ""
    @State var messageContact :String = ""
    @State private var requestToChooseAccount: Bool = false
    @State private var encryptedFormattedContent = ""
    @State private var fromAccount = ""
    @State private var pickedNumber: String?
    @State private var isMessaging = false
    @State private var isShowingMessages = false
    @State var dissmissRequested: Bool = false
    
    var decoder: Decoder?
    private var platformName: String
    var message: Messages?

    
    init(platformName: String, message: Messages? = nil) {
        self.platformName = platformName
        
        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", platformName))
        
        if message != nil {
            _messages = FetchRequest<MessageEntity>(
                sortDescriptors: [NSSortDescriptor(
                    keyPath: \MessageEntity.date,
                    ascending: true)
                ],
                predicate: NSPredicate(
                    format: "platformName == %@ and toAccount == %@ and fromAccount == %@",
                    platformName, message!.toAccount, message!.fromAccount))
            print("toAccount: \(message!.toAccount), fromAccount: \(message!.fromAccount)")
        }
        else {
            print("Yes nil")
            _messages = FetchRequest<MessageEntity>(
                sortDescriptors: [NSSortDescriptor(
                    keyPath: \MessageEntity.date,
                    ascending: true)
                ],
                predicate: NSPredicate(
                    format: "platformName == %@", platformName)
            )
            
        }

        print("Searching platform: \(platformName)")

        self.message = message
    }
    

    var body: some View {
        NavigationView {
            VStack {
                Text("Select a contact to send a message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Make sure phone code e.g +237 is included in the selected number")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                VStack {
                    Text("From: \(fromAccount)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextInputField(
                        placeHolder: "To: ",
                        textValue: $messageContact,
                        endIcon: Image("Phonebook"), function: {
                            openContactPicker()
                        })
                    .keyboardType(.phonePad)
                    
                }
                .padding()
                
                if messages.isEmpty {
                    Spacer()
                    Text("No messages sent")
                        .font(.title)
                    Spacer()
                }
                else {
                    VStack {
                        Text("Click the message to re-use for sending...")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                        List(messages, id: \.id) { inbox in
                            Button {
                                messageBody = inbox.body ?? ""
                            } label: {
                                VStack {
                                    Text(inbox.body!)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text(Date(timeIntervalSince1970: TimeInterval(inbox.date)), style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding()
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    FieldMultiEntryTextDynamic(text: $messageBody)
                        .padding()
                        .multilineTextAlignment(.leading)
                        .keyboardType(.alphabet)
                        .focused($isFocused)

                    Button {
                        isMessaging = true
                        let platform = platforms.first!
                        DispatchQueue.background(background: {
                            do {
                                let messageComposer = try Publisher.publish(
                                    context: context)
                                var shortcode: UInt8? = nil
                                shortcode = platform.shortcode!.bytes[0]
                                
                                messageContact = messageContact.filter{ $0.isWholeNumber }
                                encryptedFormattedContent = try messageComposer.messageComposer(
                                    platform_letter: shortcode!,
                                    sender: fromAccount,
                                    receiver: messageContact,
                                    message: messageBody)
                                
                                isMessaging = false
                                isShowingMessages.toggle()
                            } catch {
                                print("Some error occured while sending: \(error)")
                            }
                        })
                    } label: {
                        Image("MessageSend")
                            .resizable()
                            .frame(width: 25.0, height: 25.0)
                    }
                    .disabled(isMessaging || fromAccount.isEmpty || messageBody.isEmpty)
                    .sheet(isPresented: $isShowingMessages) {
                        SMSComposeMessageUIView(
                            recipients: [defaultGatewayClientMsisdn],
                            body: $encryptedFormattedContent,
                            completion: handleCompletion(_:))
                        .ignoresSafeArea()
                    }
                    .padding()
                }
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 1))
                .padding()
            }
            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dissmissRequested
                ) {
                    requestToChooseAccount.toggle()
                }
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
        }
        .onChange(of: dissmissRequested) { state in
            if state {
                dismiss()
            }
        }
        .onReceive(coordinator.$pickedNumber, perform: { phoneNumber in
            self.messageContact = phoneNumber ?? ""
        })
        .navigationBarTitle("Compose Message")
        .task {
            if message != nil {
                self.messageContact = message!.toAccount
                self.fromAccount = message!.fromAccount
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
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
                let date = Int(Date().timeIntervalSince1970)
                var messageEntities = MessageEntity(context: context)
                messageEntities.id = UUID()
                messageEntities.platformName = platformName
                messageEntities.fromAccount = fromAccount
                messageEntities.toAccount = messageContact
                messageEntities.subject = messageContact
                messageEntities.body = messageBody
                messageEntities.date = Int32(date)
                
                DispatchQueue.main.async {
                    do {
                        try context.save()
                        messageBody = ""
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
    
    func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = coordinator
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(contactPicker, animated: true, completion: nil)
    }
     
    class Coordinator: NSObject, ObservableObject, CNContactPickerDelegate {
        @Published var pickedNumber: String?
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Clear the pickedNumber initially
            self.pickedNumber = nil
            
            // Check if the contact has selected phone numbers
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                handlePhoneNumber(phoneNumber)
            }
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            
            if contactProperty.key == CNContactPhoneNumbersKey,
               let phoneNumber = contactProperty.value as? CNPhoneNumber {
                
                let phoneNumberString = phoneNumber.stringValue
                // Now phoneNumberString contains the phone number
                print("Phone Number: \(phoneNumberString)")
                
                // You can now use phoneNumberString as needed
                handlePhoneNumber(phoneNumberString)
            }
        }
        
        private func handlePhoneNumber(_ phoneNumber: String) {
            let phoneNumberWithoutSpace = phoneNumber.replacingOccurrences(of: " ", with: "")
            
            // Check if the phone number starts with "+"
            let sanitizedPhoneNumber = phoneNumberWithoutSpace.hasPrefix("+") ? String(phoneNumberWithoutSpace.dropFirst()) : phoneNumberWithoutSpace
            
            DispatchQueue.main.async {
                self.pickedNumber = sanitizedPhoneNumber
            }
        }
    }
}

struct MessageView_Preview: PreviewProvider {
    static var previews: some View {
        @State var dissmissRequested = false
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        let message = Messages(
            id: UUID(),
            subject: "Subject",
            data: "Hello world",
            fromAccount: "+137123456781",
            toAccount: "+137123456781", platformName: "telegram",
            date: Int(Date().timeIntervalSince1970))
        
        return MessagingView(
            platformName: "telegram",
            message: message
        ).environment(\.managedObjectContext, container.viewContext)
    }
}
