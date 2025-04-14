//
//  SaveRevokePlatform.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 25/03/2025.
//

import SwiftUI

struct SaveRevokePlatform: View {
    var name: String

    @Binding var isSaving: Bool
    @Binding var isRevoking: Bool

    @State var isAnimating = false

    var body: some View {
        VStack {
            if(isSaving) {
                Text("Saving new account for \(name)...")
                    .padding()
                    .scaleEffect(isAnimating ? 1.0 : 1.2)
                    .onAppear() {
                        withAnimation(
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                        ) {
                            isAnimating = true
                        }
                    }

            }
            else if(isRevoking) {
                Text("Revoking account for \(name)...")
                    .padding()
                    .scaleEffect(isAnimating ? 1.0 : 1.2)
                    .onAppear() {
                        withAnimation(
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                        ) {
                            isAnimating = true
                        }
                    }

            }
            ProgressView()
        }
    }
}

#Preview {
    @State var savingPlatform = true
    @State var isRevoking = false
    SaveRevokePlatform(
        name: "RelaySMS",
        isSaving: $savingPlatform,
        isRevoking: $isRevoking
    )
}
