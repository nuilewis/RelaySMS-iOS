//
//  LoginWithInternet.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct LoginWithInternet: View {
    @State private var sheetCreateAccountIsPresented: Bool = false
    @State private var sheetLoginIsPresented: Bool = false
    @State private var isLoggedIn: Bool = false
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequsted: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Login with internet")
                .font(RelayTypography.titleLarge)
                .foregroundColor(Color("AccentColor"))

            Text("These features requires you to have an internet connection")
                .font(.caption)
                .multilineTextAlignment(.center)
        }

        HStack(spacing: 8) {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {

                Label("Sign up", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.relayButton(variant: .secondary))
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
                CreateAccountSheetView(
                    createAccountSheetRequested: $createAccountSheetRequsted,
                    parentSheetShown: $sheetCreateAccountIsPresented)
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)

            Button(action: {
                sheetLoginIsPresented.toggle()
            }) {
                Label("Log in", systemImage: "person.crop.circle.badge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.relayButton(variant: .secondary))
            .sheet(isPresented: $sheetLoginIsPresented) {
                LoginSheet(
                    loginSheetRequested: $loginSheetRequested,
                    parentSheetShown: $sheetLoginIsPresented)
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)
        }
    }
}
