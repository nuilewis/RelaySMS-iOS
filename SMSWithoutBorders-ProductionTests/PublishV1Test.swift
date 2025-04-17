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
        
        // Arrange
        /// Assume the user has already signed in.
        /// Migrate their platforms to the device
        /// Assert that the platforms exist
        /// Read the stored platfoms
        /// extract the tokens
        /// construct a payload for publisher v1
        ///
        
        // This assumes the user is already signed in
        // log in with a demo account and get the llt token (the token between the user and relay)
        
        let context = makeInMemoryManagedObjectContext()
        let vault = Vault()
        let publisher = Publisher()
        let authenticationResponse =   try  vault.authenticateEntity(context: context, phoneNumber: "+237000011111", password: "ABCdef124!", ownershipResponse: "123456" )
    

        XCTAssertNotNil(authenticationResponse.longLivedToken, "Long lived token should not be null")
        
        let ltt = authenticationResponse.longLivedToken


//        let ltt = try Vault.getLongLivedToken()
//        XCTAssertNotNil(ltt, "Long lived token from keychain should not be null")
//
        let response = try vault.listStoredEntityToken(longLiveToken: ltt, migrateToDevice: true)
        response.storedTokens.forEach { token in
            XCTAssertNotNil(token)
            XCTAssertTrue(token.isStoredOnDevice, "is stored on device should be true")
        }
        
        
        
        // Publish
       let publishMessageComposer = try Publisher.publishV1(context: context)
//        publishMessageComposer.messageComposerV1(platform_letter: "g".utf8.first, sender: "237000000000", receiver: "lewisnuikweh@gmail.com", message: "Test message")
        
        // Message
        let fromNumber: String = "237000000000"
        let to: String = "lewisnuikweh@gmail.com"
        let cc: String = ""
        let bcc: String = ""
        let subject: String = "Test Email"
        let message: String = "Hello World"
        
        let platfomLetter = "g".utf8.first!
        
        let composeEmaileResponse = try  publishMessageComposer.emailComposerV1(platform_letter: "g".utf8.first!, from: fromNumber, to: to, cc: cc, bcc: bcc, subject: subject, body: message)
        
        XCTAssertNotNil(composeEmaileResponse, "Compose email response should not be null")
        
        
    }
    
}
