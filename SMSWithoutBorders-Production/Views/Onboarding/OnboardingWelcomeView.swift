//
//  SwiftUIView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @Binding var pageIndex: Int
    
    var body: some View {
        VStack {
            Text("Welcome to RelaySMS!")
                .font(Font.custom("unbounded", size: 18))
                .fontWeight(.semibold)
                .padding(.top, 40)
                
                
            VStack {
                Image("1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                LanguageSelectorButtonView()


                Text(String(localized: "Use SMS to make a post, send emails and messages with no internet connection", comment: "Explains that you can use Relay to make posts, and send emails and messages without an internet conenction"))
                    .font(Font.custom("unbounded", size: 18))
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                

            }.padding()
            
            Button {
                pageIndex += 1
            } label: {
                Text("Learn how it works")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()

            Button {
                
            } label: {
                Text("Read our privacy policy")
            }
        }
    }
}

#Preview {
    @State var pageIndex = 0
    OnboardingWelcomeView(pageIndex: $pageIndex)
}



struct LanguageSelectorButtonView: View {
    @EnvironmentObject var languageManager: LanguagePreferencesManager
    @State private var selectedLang: Language
    @State private var showLanguageChangeConfirmationAlert = false
    
    init() {
        // Gets current language code from user preferences
        let currentCode: String = LanguagePreferencesManager.getStoredLanguageCode()
        // Sets selectedLanguage code as current language or defaults to English
       selectedLang = LanguagePreferencesManager.getLanguageFromCode(langCode: currentCode) ?? Language(label: "English", endonym: "English", code: "en") // Should refactor this to use some sort of enhanced enums
        _selectedLang = State(initialValue: selectedLang)
    }
    

    var body: some View {
        Button(
            action: {
                showLanguageChangeConfirmationAlert = true
            },
            label: {
                Label(LanguagePreferencesManager.getLanguageFromCode(langCode: String(languageManager.currentLanguageCode.split(separator: "-").first ?? "n/a"))?.endonym ?? "Select Language", systemImage: "globe")
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            })
        .alert("Change App Language", isPresented: $showLanguageChangeConfirmationAlert) {
            Button("Cancel", role: .cancel){
                showLanguageChangeConfirmationAlert = false
            }
            Button("Open Settings"){
                // Open language settings page instead
                if let url: URL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                
            }
        } message: {
            Text(String(localized: "Continue to iOS settings and select your preferred language for RelaySMS.", comment: "Instructions for chnaging application langueg via system settings.") )
        }
    }
}

#Preview {
    LanguageSelectorButtonView()
}
