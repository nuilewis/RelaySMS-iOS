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
                
                Button("English", systemImage: "globe") {
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                .cornerRadius(38.5)
                .padding()

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
