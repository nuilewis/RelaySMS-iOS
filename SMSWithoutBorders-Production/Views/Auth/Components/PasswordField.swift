//
//  PasswordField.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 04/04/2025.
//

import SwiftUI

struct PasswordField: View {
    var placeholder: String?
    @Binding var text: String
    @State private var showPassword: Bool = false
    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool


    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(placeholder ?? "Password", text: $text)
                .textInputAutocapitalization(.never)
                .textContentType(.password)
                .autocorrectionDisabled(true)
                .focused($focus1)
                .opacity(showPassword ? 1 : 0)
            SecureField(placeholder ?? "Password", text: $text)
                .textInputAutocapitalization(.never)
                .textContentType(.password).focused($focus2)
                .autocorrectionDisabled(true)
                .opacity(showPassword ? 0 : 1)
        }.overlay(alignment: .trailing) {
            Image(systemName: showPassword ? "eye.slash": "eye").onTapGesture {
                showPassword.toggle()
                if showPassword { focus1 = true}
                else {focus2 = true}
            }
        }
        
    }
}

