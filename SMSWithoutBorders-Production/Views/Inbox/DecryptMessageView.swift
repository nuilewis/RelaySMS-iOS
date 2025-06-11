//
//  DecryptMessageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import CoreData
import SwiftUI

struct DecryptMessageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    @State var textBody = ""
    @State var placeHolder = String(localized: "Click to paste...")

    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    @State var alertTitle: String = ""

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Paste encrypted text into this box...")
                        .font(.subheadline)
                        .padding(.bottom, 24)

                    Text(
                        String(
                            localized:
                                "An example message...\n\nRelaySMS Reply Please paste this entire message in your RelaySMS app\n3AAAAGUoAAAAAAAAAAAAAADN2pJG+1g5bNt1ziT84plbYcgwbbp+PbQHBf7ekxkOO...",
                            comment:
                                "Shows an explain message which can be pasted into the inbox view and decrypted"
                        )
                    )
                    .font(.caption2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)

                VStack {
                    ZStack {
                        if self.textBody.isEmpty {
                            TextEditor(text: $placeHolder)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .disabled(true)
                                .frame(height: 200)
                        }
                        TextEditor(text: $textBody)
                            .font(.caption)
                            .opacity(self.textBody.isEmpty ? 0.25 : 1)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(height: 200)

                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                textBody.isEmpty
                                    ? RelayColors.colorScheme.onSurface.opacity(
                                        0.1) : RelayColors.colorScheme.primary,
                                lineWidth: 1)
                    )
                    .padding(.bottom, 24)
                 

                }.alert(alertTitle, isPresented: $showAlert) {
                } message: {
                    Text(alertMessage)
                }

                HStack {
                    Button {
                        do {
                            let decryptedText =
                                try Bridges.decryptIncomingMessages(
                                    context: context,
                                    text: textBody
                                )
                            print(decryptedText)
                            DispatchQueue.background(
                                background: {
                                    let date = Int(Date().timeIntervalSince1970)

                                    var messageEntities = MessageEntity(
                                        context: context)
                                    messageEntities.id = UUID()
                                    messageEntities.platformName =
                                        Bridges.SERVICE_NAME
                                    messageEntities.fromAccount =
                                        decryptedText.fromAccount
                                    messageEntities.toAccount = ""
                                    messageEntities.cc = decryptedText.cc
                                    messageEntities.bcc = decryptedText.bcc
                                    messageEntities.subject =
                                        decryptedText.subject
                                    messageEntities.body = decryptedText.body
                                    messageEntities.date = decryptedText.date
                                    messageEntities.type =
                                        Bridges.SERVICE_NAME_INBOX

                                    DispatchQueue.main.async {
                                        do {
                                            try context.save()
                                        } catch {
                                            print(
                                                "Failed to save message entity: \(error)"
                                            )
                                        }
                                    }
                                },
                                completion: {
                                    dismiss()
                                })
                        } catch {
                            print("Error decrypting: \(error)")
                        }
                    } label: {
                        Text("Decrypt message")
                    }
                    .buttonStyle(.relayButton(variant: .primary))
                    .controlSize(.large)
                    .tint(.accentColor)
                    .disabled(textBody.isEmpty)

                    Button {
                        if !textBody.isEmpty {
                            retirieveTwitterTokens(reply: textBody)
                        } else {
                            print("Text body is empty")
                            showAlert = true
                            alertTitle = "Error"
                            alertMessage = "Please enter a message to decrypt"
                        }

                    } label: {
                        Text("Update Twitter")
                    }
                    .buttonStyle(.relayButton(variant: .secondary))
                    .controlSize(.large)
                    .tint(.accentColor)
                    .disabled(textBody.isEmpty)
                }
            }.padding()

        }

        .navigationTitle("Decrypt Message")
    }

    //Might move

    func retirieveTwitterTokens(reply: String) {

        alertTitle = "Error"
        alertMessage = "Failed to process request"

        let decodedReply = String(
            data: Data(base64Encoded: reply) ?? Data(), encoding: .utf8)
        if let decodedString = decodedReply, !decodedString.isEmpty {
            print("Successfully decoded the twitter reply: \(decodedString)")

            do {
                //Extract the refresh tokens
                let refreshToken = decodedString
                let platformName = "twitter"

                let fetchRequest: NSFetchRequest<StoredPlatformsEntity> = StoredPlatformsEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", platformName)

                let existingEntity = try context.fetch(fetchRequest).first

                if let entityToUpdate = existingEntity {
                    do {
                        try Vault.saveStoredPlatform(
                            context: context,
                            id: entityToUpdate.id ?? "",
                            name: entityToUpdate.name ?? "",
                            account: entityToUpdate.account ?? "",
                            isStoredOnDevice: entityToUpdate.is_stored_on_device,
                            accessToken: existingEntity?.access_token,
                            refreshToken: refreshToken
                        )
                        print("Successfully updated the Twitter refresh token")
                        alertTitle = "Success"
                        alertMessage = "Successfully updated the Twitter refresh token"

                    } catch {
                        alertTitle = "Failed"
                        alertMessage = "Unable to update the refresh token for Twitter"
                        print("Unable to update the refresh token for twitter: \(error)")

                    }
                } else {
                    alertTitle = "Failed"
                    alertMessage = "Twitter platform not found, please add it first"

                }
            } catch {
                alertTitle = "Error"
                alertMessage = "Failed to fetch Twitter platform: \(error.localizedDescription)"
                print(error)
            }

        } else {
            alertTitle = "Error"
            alertMessage = "Failed to decode the message"
        }

        showAlert = true
    }
}

#Preview {
    DecryptMessageView()
}
