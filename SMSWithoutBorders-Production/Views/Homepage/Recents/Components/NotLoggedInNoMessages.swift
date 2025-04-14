//
//  NotLoggedInEmptyMessages.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct NotLoggedInNoMessages: View {
    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool

    var body: some View {
            VStack(spacing: 10) {
                Spacer()
                SendFirstMessage(
                    composeNewSheetRequested: $composeNewMessageRequested
                )
                Spacer()
                LoginWithInternet(
                    loginSheetRequested: $loginSheetRequested,
                    createAccountSheetRequsted: $createAccountSheetRequested
                ).padding(.bottom, 48)
//                    WalkthroughViews(sheetCreateAccountIsPresented: $walkthroughViewsShown)
            }
            .navigationTitle("Get Started")
            .padding([.trailing, .leading], 16)
    }
}
