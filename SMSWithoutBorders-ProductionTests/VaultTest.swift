//
//  Vault1Test.swift
//  SMSWithoutBorders-ProductionTests
//
//  Created by sh3rlock on 25/06/2024.
//

import GRPC
import NIO
import XCTest
import Logging
import CryptoKit
import Fernet
import SwobDoubleRatchet

@testable import SMSWithoutBorders

class VaultTest: XCTestCase {
    var vault = Vault()
    var password = "dMd2Kmo9#"
    var phoneNumber = "+2371123457528"
    var ownershipProof = "123456"

    func testEndToEnd() async throws {
        let context = DataController().container.viewContext
        
        try Vault.resetKeystore(context: context)
        Bridges.reset()
        
        let countryCode = "CM"
        
        do {
            var entityCreationResponse = try vault.createEntity(
                context: context,
                phoneNumber: phoneNumber,
                countryCode: countryCode,
                password: password)
            
            XCTAssertTrue(entityCreationResponse.requiresOwnershipProof)
            XCTAssertNotNil(entityCreationResponse.serverDeviceIDPubKey)

            entityCreationResponse = try vault.createEntity(
                context: context,
                phoneNumber: phoneNumber,
                countryCode: countryCode,
                password: password,
                ownershipResponse: ownershipProof)
            print("message says: \(entityCreationResponse.message)")
            
            
            XCTAssertFalse(entityCreationResponse.requiresOwnershipProof)
        } catch Vault.Exceptions.requestNotOK(let status){
            print("Error came back - message: \(status.message)")
            print("Error came back - cause: \(status.cause)")
            print("Error came back - description: \(status.cause)")
            print("Error came back - code: \(status.code)")
            if status.code.rawValue != 6 {
                throw status
            }
        }
        
        
        var response = try vault.authenticateEntity(
            context: context,
            phoneNumber: phoneNumber,
            password: password
        )
            
        XCTAssertTrue(response.requiresOwnershipProof)

        // ** LOGIN **
        response = try vault.authenticateEntity(
            context: context,
            phoneNumber: phoneNumber,
            password: password,
            ownershipResponse: ownershipProof
        )
        

        // ** LIST STORED TOKENS **
        let llt = try Vault.getLongLivedToken()
        XCTAssertNotNil(llt)
        
        let response1 = try vault.listStoredEntityToken(longLiveToken: llt)
        print("stored tokens: \(response1.storedTokens)")
        
        XCTAssertNotNil(UserDefaults.standard.object(forKey: Bridges.CLIENT_PUBLIC_KEY_KEYSTOREALIAS))
        XCTAssertNotNil(UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY))

            // ** REVOKE STORED TOKENS **
//            let publisher = Publisher()
//            for platform in response1.storedTokens {
//                print("Revoking: \(platform.platform): \(platform.accountIdentifier)")
//                let response = try publisher.revokePlatform(llt: llt!,
//                                         platform: platform.platform,
//                                         account: platform.accountIdentifier)
//                
//                XCTAssertTrue(response.success)
//            }
//            
//            // ** DELETE STORED TOKENS **
//            let deleteResponse = try vault.deleteEntity(longLiveToken: llt!)
//            print("Deleted tokens...")
//            
//            XCTAssertTrue(deleteResponse.success)
        
        var to = "wisdomnji@gmail.com"
        var cc = ""
        var bcc = ""
        var subject = "Test email"
        
        let messageComposer = try Publisher.publish(context: context, checkPhoneNumberSettings: false)
        let encryptedCipherText = try messageComposer.emailComposer(
            platform_letter: "g".data(using: .utf8)!.first!,
            from: "anarchist.sonsofperdition@gmail.com",
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: "Hello world - platforms"
        )
        
        var responseCode = try await BridgesTest.executePayload(phoneNumber: phoneNumber, payload: encryptedCipherText)
        XCTAssertEqual(responseCode, 200)

        var (cipherText, clientPublicKey) = try Bridges.compose(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: "Hello world - Bridges",
            context: context
        )

        let payload = try Bridges.payloadOnly(context: context, cipherText: cipherText)
        
        print("Executing first stage... auth + payload")
        responseCode = try await BridgesTest.executePayload(phoneNumber: phoneNumber, payload: payload!)
        XCTAssertEqual(responseCode, 200)
        print("- First stage complete")
    }
}
