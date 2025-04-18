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
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            
            if let error = error {
                fatalError("Failed to load in-memoery store: \(error)")
            }
        }
        return container.viewContext
    }
    
    
    func testSignInUserAndPublishV1ShouldPublish() throws {
        
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
        var authenticationResponse = try  vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!")
        authenticationResponse = try vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!", ownershipResponse: "123456")
        
        XCTAssertNotNil(authenticationResponse.longLivedToken, "Long lived token should not be null")
        XCTAssertFalse(authenticationResponse.longLivedToken == "", "Long lived token should not be empty")
        let ltt = authenticationResponse.longLivedToken
       
        
        // Get Platform tokens from vault
        let response = try vault.listStoredEntityToken(longLiveToken: ltt, migrateToDevice: true)
        response.storedTokens.forEach { token in
            XCTAssertNotNil(token)
            XCTAssertTrue(token.isStoredOnDevice, "is stored on device should be true")
        }
        
        // Extract Tokens
        let gmailPlatformToken = response.storedTokens.first { token in token.platform == "gmail"}
        XCTAssertNotNil(gmailPlatformToken, "gmail platform token should not be null")
        var gAccessToken: String = ""
        var gRefreshToken: String = ""
        
        if let accountTokens = gmailPlatformToken?.accountTokens {
            gAccessToken = accountTokens["access_token"]!
            gRefreshToken = accountTokens["refresh_token"]!
            XCTAssertFalse(gAccessToken == "", "Access token should not be empty")
            XCTAssertFalse(gRefreshToken == "", "Refresh token should not be empty")
        }
    
        
        // Publish
        // 1. Compose email
        let publishMessageComposer = try Publisher.publishV1(context: context)
        
        let fromNumber: String = "237000000000"
        let to: String = "lewisnuikweh@gmail.com"
        let cc: String = ""
        let bcc: String = ""
        let subject: String = "Test Email"
        let message: String = "Hello World"
        let platfomLetter = "g".utf8.first!
        
        let composeEmailResponse = try publishMessageComposer.emailComposerV1(platform_letter: platfomLetter, from: fromNumber, to: to, cc: cc, bcc: bcc, subject: subject, body: message, accessToken: gAccessToken, refreshToken:  gRefreshToken)
        
        XCTAssertNotNil(composeEmailResponse, "Compose email response should not be null")
        
        // 2. Trigger publish
        
        
    }
    
}
