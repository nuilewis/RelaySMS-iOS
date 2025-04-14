//
//  DecryptMessageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct DecryptMessageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    @State var textBody = ""
    @State var placeHolder = String(localized:"Click to paste...")

    var body: some View {
        VStack {
            VStack {
                Text("Paste encrypted text into this box...")
                    .font(.subheadline)
                    .padding(.bottom, 32)

                Text(String(localized:"An example message...\n\nRelaySMS Reply Please paste this entire message in your RelaySMS app\n3AAAAGUoAAAAAAAAAAAAAADN2pJG+1g5bNt1ziT84plbYcgwbbp+PbQHBf7ekxkOO...", comment: "Shows an explain message which can be pasted into the inbox view and decrypted"))
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
                    }
                    TextEditor(text: $textBody)
                        .font(.caption)
                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(textBody.isEmpty ? RelayColors.colorScheme.onSurface.opacity(0.1) : RelayColors.colorScheme.primary, lineWidth: 2)
                )
            }

            VStack {
                Button {
                    do {
                        let decryptedText = try Bridges.decryptIncomingMessages(
                            context: context,
                            text: textBody
                        )
                        print(decryptedText)
                        DispatchQueue.background(background: {
                            let date = Int(Date().timeIntervalSince1970)

                            var messageEntities = MessageEntity(context: context)
                            messageEntities.id = UUID()
                            messageEntities.platformName = Bridges.SERVICE_NAME
                            messageEntities.fromAccount = decryptedText.fromAccount
                            messageEntities.toAccount = ""
                            messageEntities.cc = decryptedText.cc
                            messageEntities.bcc = decryptedText.bcc
                            messageEntities.subject = decryptedText.subject
                            messageEntities.body = decryptedText.body
                            messageEntities.date = decryptedText.date
                            messageEntities.type = Bridges.SERVICE_NAME_INBOX

                            DispatchQueue.main.async {
                                do {
                                    try context.save()
                                } catch {
                                    print("Failed to save message entity: \(error)")
                                }
                            }
                        }, completion: {
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
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Decrypt Message")
        .padding()
    }
}

#Preview {
    DecryptMessageView()
}
