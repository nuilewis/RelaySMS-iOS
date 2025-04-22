//
//  PublishV1Test.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 17/04/2025.
//
import XCTest
@testable import SMSWithoutBorders
import CoreData

public class PublishV1Test: XCTestCase {

    private func makeInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Datastore")
        let description = NSPersistentStoreDescription()
      //  description.type = NSInMemoryStoreType /// This doesnt support batch operations causing the test to fail. Rather user a work around
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            
            if let error = error {
               // fatalError("Failed to load in-memoery store: \(error)")
                fatalError("Failed to load SQLite store for tests pointed to /dev/null: \(error)")
            } else {
                print("SQLite container for testing loaded successfully (URL: \(description.url?.absoluteString ?? "nil")).")
            }
        }
        return container.viewContext
    }
    
    
    func testSignInUserAndPublishV1ShouldPublish() async throws {
        /// Arrange
        /// Assume the user has already signed in.
        /// Migrate their platforms to the device
        /// Assert that the platforms exist
        /// Read the stored platfoms
        /// extract the tokens
        /// construct a payload for publisher v1
        ///
        
        /// This assumes the user is already created and has already added the Gmail platfom to their account
        

        // Arrange
        let vault: Vault = Vault()
        let context: NSManagedObjectContext = makeInMemoryManagedObjectContext()
        let publisher = Publisher()
        
        // Authenticate : Sign in, verify account and get LLT
        var authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237679670522", password: "Myrelaysmsaccount1!")
        
        //var authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237123456789", password: "dummy_password")
       
        if authenticationResponse.requiresOwnershipProof {
            print("Requires owenserhip proof (OTP): \(authenticationResponse.requiresOwnershipProof)")
            authenticationResponse = try vault.authenticateEntity(context: context, phoneNumber: "+237679670522", password: "Myrelaysmsaccount1!", ownershipResponse: "123456")
            print("Authentication Response after OTP : \(authenticationResponse)")
//            authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237123456789", password: "dummy_password", ownershipResponse: "123456")
        }

        
        XCTAssertNotNil(authenticationResponse.longLivedToken, "Long lived token should not be null")
        XCTAssertFalse(authenticationResponse.longLivedToken == "", "Long lived token should not be empty")
        let encryptedLlt = authenticationResponse.longLivedToken
        print("encryptedLlt: \(encryptedLlt)")
        // i think i have to decrrypt the ltt before using.
        // call Vault.deriveStoredLTT before using but is already called when calling authenticated entity, so the llt is already decrypted and stored.
        
        let decryptedLlt = try Vault.getLongLivedToken()
        print("decryptedLlt: \(decryptedLlt)")
       
        // Get Platform tokens from vault
        let response = try vault.listStoredEntityToken(longLiveToken: decryptedLlt, migrateToDevice: true)
        response.storedTokens.forEach { token in
            XCTAssertNotNil(token)
            XCTAssertTrue(token.isStoredOnDevice, "is stored on device should be true")
           // XCTAssertFalse(token.isStoredOnDevice, "is stored on device should be false")
            print("Available Platforms tokens: \(token)")
        }
        
        // Extract Tokens
        let twitterPlatformToken = response.storedTokens.first { token in token.platform == "twitter"}
        let gmailPlatformToken = response.storedTokens.first { token in token.platform == "gmail"}
       // XCTAssertNotNil(twitterPlatformToken, "twitter platform token should not be null")
       // XCTAssertNotNil(gmailPlatformToken, "Gmail platform token should not be null")
        
        var tAccessToken: String = ""
        var tRefreshToken: String = ""
        var gAccessToken: String = ""
        var gRefreshToken: String = ""
        
        if let twitterAccountTokens = twitterPlatformToken?.accountTokens {
            tAccessToken = twitterAccountTokens["access_token"]!
            tRefreshToken = twitterAccountTokens["refresh_token"]!
           // XCTAssertFalse(tAccessToken == "", "Access token should not be empty")
          //  XCTAssertFalse(tRefreshToken == "", "Refresh token should not be empty")
        }
        
        if let gmailAccountTokens = gmailPlatformToken?.accountTokens {
            gAccessToken = gmailAccountTokens["access_token"]!
            gRefreshToken = gmailAccountTokens["refresh_token"]!
            XCTAssertFalse(gAccessToken == "", "Access token should not be empty")
            XCTAssertFalse(gRefreshToken == "", "Refresh token should not be empty")
        }
    
        
        // Publish
        // 1. Compose twitter message
        let publishMessageComposer = try Publisher.publish(context: context)
        
        let sender: String = "nuilewis"
        let message: String = "Hello World"
        let twitterPlatfomLetter = "t".utf8.first!
        let twitterComposerResponse = try publishMessageComposer.textComposerWithToken(
            platform_letter: twitterPlatfomLetter,
            sender: sender,
            text: message,
            accessToken: tAccessToken,
            refreshToken: tRefreshToken
        )
        
        // 1b. Compose gmail message
        let from: String = "lewisnuikweh@gmail.com"
        let to: String = "lnuikweh@gmail.com"
        let cc: String = ""
        let bcc: String = ""
        let subject: String = "Test email from RelaySMS"
        let body: String = "Hello World"
        let gmailPlatformLetter = "g".utf8.first!
    
        let gmailComposerResponse = try publishMessageComposer.emailComposerWithToken(
            platform_letter: gmailPlatformLetter,
            from: from,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: body,
            accessToken: gAccessToken,
            refreshToken: gRefreshToken
        )
        

        // 2. Trigger publish
        let twitterData: [String: String] = [
            "text": twitterComposerResponse,
            "MSISDN": "+237679670522",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        let gmailData: [String: String] = [
            "text": gmailComposerResponse,
            "MSISDN": "+237679670522",
            "date": "2025-04-22",
            "date_sent": "2025-04-22",
        ]
        
        let url: URL = URL(string:"https://gatewayserver.staging.smswithoutborders.com/v3/publish")!
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataSerialized = try JSONSerialization.data(withJSONObject: gmailData, options: [])
        request.httpBody = dataSerialized
        
        print("Serialized http body data: \(String(data: dataSerialized, encoding: .utf8) ?? "Error serializing data")")
        print("Sending Publishing request: \(request)")
        
        let (_data, apiResponse) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any] {
            print("Publishing response json : \(json)")
        }
        let httpResponse = apiResponse as? HTTPURLResponse
        print("full response: \(String(describing: httpResponse))")
        XCTAssertTrue(httpResponse?.statusCode == 200, "Should publish successfully")
    }
    
}
