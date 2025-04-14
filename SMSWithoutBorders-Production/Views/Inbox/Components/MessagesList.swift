//
//  MessagesList.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct MessagesList: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @Binding var pasteIncomingRequested: Bool

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    init(
        pasteIncomingRequested: Binding<Bool>,
        requestedMessage: Binding<Messages?>,
        emailIsRequested: Binding<Bool>
    ) {
        _pasteIncomingRequested = pasteIncomingRequested
        _requestedMessage = requestedMessage
        _emailIsRequested = emailIsRequested

        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "type == %@", Bridges.SERVICE_NAME_INBOX)
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                List(inboxMessages, id: \.self) { message in
                    MessageCard(
                        logo: getImageForPlatform(name: message.platformName!),
                        subject: message.subject!,
                        toAccount: message.toAccount!,
                        messageBody: message.body!,
                        date: Int(message.date)
                    )
                    .onTapGesture {
                        requestedMessage = Messages(
                            id: message.id!,
                            subject: message.subject!,
                            data: message.body!,
                            fromAccount: message.fromAccount!,
                            toAccount: message.toAccount!,
                            platformName: message.platformName!,
                            date: Int(message.date)
                        )
                        if message.type == Bridges.SERVICE_NAME_INBOX ||
                            message.type == Bridges.SERVICE_NAME {
                            emailIsRequested.toggle()
                        }
                    }
                }
            }
            VStack {
                Button {
                    pasteIncomingRequested.toggle()
                } label: {
                    Image(systemName: "document.on.clipboard")
                        .font(.system(.title))
                        .frame(width: 57, height: 50)
                        .foregroundColor(Color.white)
                        .padding(.bottom, 7)
                }
                .background(.blue)
                .cornerRadius(18)
                 .shadow(color: Color.black.opacity(0.3),
                         radius: 3,
                         x: 3,
                         y: 3
                 )
            }
            .padding()
        }
    }

    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter { $0.name == name}.first?.image
        if image != nil {
            return Image( uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}

struct MessagesPresent_Preview: PreviewProvider {
    static var previews: some View {
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested: Bool = false

        @State var pasteIncomingRequested = false
        return MessagesList(
            pasteIncomingRequested: $pasteIncomingRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

