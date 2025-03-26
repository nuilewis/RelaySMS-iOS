//
//  Recents1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 21/01/2025.
//

import SwiftUI


struct RecentsNotLoggedInView: View {
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

    @State var walkthroughViewsShown: Bool = false

    @Binding var isLoggedIn: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var createAccountSheetRequested: Bool
    @Binding var loginSheetRequested: Bool

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    var body: some View {
        NavigationView {
            VStack {
                if !messages.isEmpty {
                    NotLoggedInMessagesPresentInbox(
                        composeNewMessageRequested: $composeNewMessageRequested,
                        loginSheetRequested: $loginSheetRequested,
                        createAccountSheetRequested: $createAccountSheetRequested,
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested
                    )
                        .navigationTitle("Recents")
                } else {
                    NotLoggedInNoMessages(
                        composeNewMessageRequested: $composeNewMessageRequested,
                        loginSheetRequested: $loginSheetRequested,
                        createAccountSheetRequested: $createAccountSheetRequested
                    )
                }
            }
        }
    }
}

struct RecentsNotLoggedInView_Preview: PreviewProvider {
    static var previews: some View {
        @State var isLoggedIn = false
        @State var composeNewMessageRequested = false
        @State var createAccountSheetRequested = false
        @State var loginSheetRequested = false
        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested = false
        RecentsNotLoggedInView(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
    }
}

struct RecentsNotLoggedInWithMessageView_Preview: PreviewProvider {
    static var previews: some View {
        @State var isLoggedIn = false
        @State var composeNewMessageRequested = false
        @State var createAccountSheetRequested = false
        @State var loginSheetRequested = false

        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested = false

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsNotLoggedInView(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

