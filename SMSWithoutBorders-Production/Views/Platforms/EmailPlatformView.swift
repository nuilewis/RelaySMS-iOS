//
//  EmailView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 09/08/2024.
//

import SwiftUI

struct EmailPlatformView: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State var message: Messages
    
    @Binding var composeNewMessageRequested: Bool
    @Binding var emailComposeRequested: Bool
    @Binding var requestedPlatformName: String

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()

                    VStack(alignment: .leading) {
                        HStack {
                            Text(message.fromAccount)
                                .bold()
                            Text(Date(timeIntervalSince1970: TimeInterval(message.date)), formatter: RelativeDateTimeFormatter())
                                .font(.caption)
                        }
                        .padding(.bottom, 8)

                        Text(message.toAccount)
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                    
                Text(message.data)
                    .padding()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                
            }
            .navigationTitle(message.subject)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        requestedPlatformName = message.platformName
                        if message.platformName.isEmpty ||
                            message.type == Bridges.SERVICE_NAME { composeNewMessageRequested = true
                        } else {
                            emailComposeRequested = true
                        }
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Messages.deleteMessage(context: context, message: message)
                        dismiss()
                    } label: {
                        Image(systemName: "trash.circle")
                    }
                }
            })
        }
    }
}

struct EmailPlatformView_Preview: PreviewProvider {
    static var previews: some View {
        @State var composeNewMessageRequested: Bool = false
        @State var emailComposeRequested: Bool = false
        @State var requestedPlatformName: String = ""

        @State var message = Messages(
            id: UUID(),
            subject: "Hello world",
            data: "Hello world",
            fromAccount: "a@g.com",
            toAccount: "toAccount@gmail.com",
            platformName: "gmail",
            date: Int(Date().timeIntervalSince1970))
        EmailPlatformView(
            message: message,
            composeNewMessageRequested: $composeNewMessageRequested,
            emailComposeRequested: $emailComposeRequested,
            requestedPlatformName: $requestedPlatformName
        )
    }
}
