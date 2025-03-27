//
//  Walkthrough.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct Walkthrough: View {
    @Binding var sheetCreateAccountIsPresented: Bool

    var body: some View {
        VStack {
            Text("Having trouble using the app?")
                .font(.headline)
            Text("Check out our step-by-step guide")
                .font(.caption)
                .multilineTextAlignment(.center)
        }

        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your RelaySMS account")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your personal accounts")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

        }
        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Choosing a country for routing your messages")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 120, y: -60)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }
        }
    }
}

// --- Preview Provider ---

#if DEBUG // Ensures this code only compiles for debug builds (like previews)
struct WalkthroughViews_Previews: PreviewProvider {
    // Create a static state variable wrapper for the preview
    // This allows you to simulate the binding
    struct PreviewWrapper: View {
        @State private var isSheetPresented: Bool = false

        var body: some View {
            Walkthrough(sheetCreateAccountIsPresented: $isSheetPresented)
        }
    }

    static var previews: some View {
        // --- Preview 1: Using @State Wrapper (allows interaction in preview) ---
        PreviewWrapper()
            .previewDisplayName("Interactive Preview")
            .padding() // Add padding around the view in the preview canvas

        // --- Preview 2: Using .constant (non-interactive binding) ---
        // Useful just to see the static layout if interaction isn't needed
        Walkthrough(sheetCreateAccountIsPresented: .constant(false))
            .previewDisplayName("Static Layout")
            .padding()
            .previewLayout(.sizeThatFits) // Adjust preview canvas size
    }
}
#endif


