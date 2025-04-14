//
//  RelayTextFieldStyle.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/03/2025.
//

import SwiftUI

struct RelayTextFieldStyle: TextFieldStyle {


    private let focusedBorderWith: CGFloat = 1
    private let unfocusedBorderWidth: CGFloat = 0

    private var isFocused: Bool = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isFocused ? RelayColors.colorScheme.primaryContainer.opacity(0.5) : RelayColors.colorScheme.surfaceContainer)

            ).overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused ? RelayColors.colorScheme.primary : RelayColors.colorScheme.surfaceContainer,
                        lineWidth: isFocused ? focusedBorderWith : unfocusedBorderWidth
                    )
            )
            .animation(.default, value: isFocused)
    }
}

struct RelayTextFieldStyleField: PreviewProvider {
    static var previews: some View {
        TextField("Sample Text", text: .constant("")).textFieldStyle(RelayTextFieldStyle()).previewLayout(.sizeThatFits).padding()
    }
}

struct RelayTextFieldStyleField2: PreviewProvider {
    // Create a stateful wrapper view for the preview
    struct PreviewWrapper: View {
        @State private var sampleText: String = ""
        @State private var focusedText: String = "Initially Focused"

        // Define the FocusState variable
        @FocusState private var isInputFocused: Bool
        @FocusState private var isSecondInputFocused: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("TextField Style Preview")
                    .font(.headline)

                Divider()

                Text("Not Focused:")
                TextField("Placeholder", text: $sampleText)
                    .textFieldStyle(RelayTextFieldStyle())
                    .focused($isInputFocused)  // Bind focus state
                    // Set the environment value based on the FocusState

                Text("Tap to Focus:")
                TextField("Another Placeholder", text: $focusedText)
                    .textFieldStyle(RelayTextFieldStyle())
                    .focused($isSecondInputFocused)  // Bind focus state for the second field

                // You can also simulate the focused state visually without interaction
                Text("Simulated Focused State:")
                TextField("Visually Focused", text: .constant("Focused"))
                    .textFieldStyle(RelayTextFieldStyle())
                    .disabled(true)  // Disable interaction for visual preview only


                // Example button to toggle focus programmatically
                Button("Focus First Field") {
                    isInputFocused = true
                }
                .padding(.top)
            }
            .padding()
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
