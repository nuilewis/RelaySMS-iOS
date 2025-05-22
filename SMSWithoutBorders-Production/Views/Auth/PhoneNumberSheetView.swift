//
//  PhoneNumberSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 03/08/2024.
//

import SwiftUI
import CountryPicker

struct PhoneNumberCodeEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>

    var platformName: String
    @Binding var phoneNumber: String
    @Binding var completed: Bool

    @State var loading = false
    @State var failed = false
    @State var havePassword = false

    @State var code: String = ""
    @State var password: String = ""
    @State var errorMessage: String = ""

    var body: some View {
        VStack {
            if platformName == "telegram" {
                Text("Please enter your Telegram code without copying it from the message - copying might get flagged and Telegram might block your account.")
                    .padding()
                    .font(.caption)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange)
                    )
                    .multilineTextAlignment(.center)
            }
            
            TextField("Enter code", text: $code)
                .padding()
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .controlSize(.large)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.gray)
                )
            
            if havePassword {
                PasswordField(placeholder: "Enter password", text: $password)
                    .padding()
                    .controlSize(.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(lineWidth: 1)
                            .foregroundColor(.gray)
                    )
            }

            if loading {
                ProgressView()
                    .padding()
            }
            else {
                Button("Submit") {
                    phoneNumberAuthExchange()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .controlSize(.large)
                .disabled(code.count < 3 || (havePassword && password.isEmpty))
            }
        }
        .padding()
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
    }
    
    func phoneNumberAuthExchange() {
        
        self.loading = true
        self.failed = false
        self.errorMessage = ""
        DispatchQueue.background(background: {
            do {
                let publisher = Publisher()
                let llt = try Vault.getLongLivedToken()
                print("Sending code for phone number: \(phoneNumber)")

                let response = try publisher.phoneNumberBaseAuthenticationExchange(
                    authorizationCode: code,
                    llt: llt,
                    phoneNumber: phoneNumber,
                    platform: platformName,
                    password: password
                )
                
                DispatchQueue.main.async {
                    if response.success {
                        if response.twoStepVerificationEnabled {
                            havePassword = true
                        } else {
                            print("Successfully stored: \(platformName)")
                            do {
                                try Vault().refreshStoredTokens(
                                    llt: llt,
                                    context: context,
                                    storedTokenEntities: storedPlatforms
                                )
                                self.completed = true
                                self.dismiss()
                            } catch {
                                print("Failed to refresh tokens: \(error)")
                                self.failed = true
                                self.errorMessage = "Failed to store platform: \(error.localizedDescription)"
                            }
              
                        }
                    }
                    else {
                         print("Failed to store platform: \(platformName)")
                    }
                }

            } catch {
                DispatchQueue.main.async {
                       print("Failed to submit code: \(error)")
                       self.failed = true
                       self.errorMessage = error.localizedDescription
                   }
            }
        }, completion: {
//            submittingCode = false
            self.loading = false
        })
    }
}

struct PhoneNumberEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName
    
    @State private var errorMessage: String = ""
    
    @State var platformName: String
    @State private var showCountryPicker = false
    @State private var submittingCode = false
    @State private var isLoading = false
    @State private var failed = false
    @State private var country: Country?
    
    @Binding var codeRequested: Bool
    @Binding var phoneNumber: String

    var body: some View {
        VStack {
            Group {
                HStack {
                    Button {
                        showCountryPicker.toggle()
                    } label: {
                        Text("+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                           .foregroundColor(Color.secondary)
                    }
                    .sheet(isPresented: $showCountryPicker) {
                        CountryPicker(
                            country: $country,
                            selectedCountryCodeText: $selectedCountryCodeText
                        )
                    }
                    Spacer()
                    TextField("\(platformName) phone number", text: $phoneNumber)
                        .padding()
                        .keyboardType(.numberPad)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
               }
               Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            .padding(.leading)
            .alert(isPresented: $failed) {
                Alert(
                    title: Text("Error! You did nothing wrong..."),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Not my fault!"))
                )
            }

            if isLoading {
                ProgressView()
                    .padding()
            }
            else {
                Button("Get code") {
                    phoneNumberAuthRequest()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(phoneNumber.count < 3)
                .controlSize(.large)
            }
        }
        .padding(.bottom, 32)
    }
    
    func phoneNumberAuthRequest() {
        self.isLoading = true
        self.failed = false
        self.errorMessage = ""
        
        DispatchQueue.background(background: {
            isLoading = true
            do {
                let publisher = Publisher()
                let response = try publisher.phoneNumberBaseAuthenticationRequest(
                    phoneNumber: getPhoneNumber(),
                    platform: platformName
                )
                
        
                
                DispatchQueue.main.async {
                    self.phoneNumber = getPhoneNumber()
                    
                    if response.success {
                        codeRequested = true
                    }else {
                        self.failed = true
                        self.errorMessage = response.message
                    }
                }
            }
            catch {
                DispatchQueue.main.async {
                    print("Some error occured: \(error)")
                    self.failed = true
                    self.errorMessage = error.localizedDescription
                }
            }
        }, completion: {
            self.isLoading = false
        })
    }
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

struct PhoneNumberSheetView: View {
    @Binding var completed: Bool
    
    @State private var phoneNumber: String = ""
    @State private var codeRequested = false
    @State private var requestingCode = false

    var platformName: String

    var body: some View {
         VStack {
             if codeRequested {
                 PhoneNumberCodeEntryView(
                    platformName: platformName,
                    phoneNumber: $phoneNumber,
                    completed: $completed
                 )
             }
             else {
                 PhoneNumberEntryView(
                    platformName: platformName,
                    codeRequested: $codeRequested,
                    phoneNumber: $phoneNumber
                 )
             }
        }
    }
    
}

#Preview {
    @State var platformName = "telegram"
    @State var completed = false
    PhoneNumberSheetView(
        completed: $completed,
        platformName: platformName
    )
}

#Preview {
    @State var platformName = "telegram"
    @State var phoneNumber = ""
    @State var completed: Bool = false
    PhoneNumberCodeEntryView(
       platformName: platformName,
       phoneNumber: $phoneNumber,
       completed: $completed
    )
}

#Preview {
    @State var platformName = "telegram"
    @State var phoneNumber = "112345"
    @State var codeRequested = false
    PhoneNumberEntryView(
        platformName: platformName,
        codeRequested: $codeRequested,
        phoneNumber: $phoneNumber
    )
}
