//
//  KeychainManagerTest.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 15/04/2025.
//

import XCTest
@testable import SMSWithoutBorders


final class KeychainManagerTest: XCTestCase {
    
    let keychainManager = KeychainManager.instance
    let testKey = "com.smswithoutborders.tesKey"
    let testToken = "AbCdEfGhIjKlMnOpQrStUvWxYz123456"
    let anotherTeskToken = "ZyXwVuTsRqPoNmLkJiHgFeDcBa987654"
    
    
    // Helper function to delete keychain items used in tests
    private func deleteTestToken(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        print("Debug: Deletion status for key '\(key)': \(status)")
    }
    
    // Setup
    override func setUpWithError() throws {
        try super.setUpWithError()
        print("Debug: setupWithError - Deleting token for key '\(testKey)'")
        deleteTestToken(forKey: testKey)
    }
    
    // Teardown
    override func tearDownWithError() throws {
        print("Debug: tearDownWithError - Deleting token for key '\(testKey)'")
        deleteTestToken(forKey: testKey)
        try super.tearDownWithError()
    }
    
    
    // MARK: - Test Cases
    
    func testSaveAndRetrieveTokenSuccess() {
        
        // Arrange - Handled above
        
   
        XCTAssertNoThrow(try keychainManager.saveToken(testToken, forKey: testKey), "Saving should not throw an error")
        
        // Act
        let retrievedToken = keychainManager.getToken(forKey: testKey)
        
        // Asert
        XCTAssertNotNil(retrievedToken, "Retrived token shoudl not be nil")
        XCTAssertEqual(retrievedToken, testToken, "Retrvied token should match saved token")
        
    }
    
    
    func testGetTokenNotFound() {
        // Act: Attempt to retrieve the token
        let retrievedToken = keychainManager.getToken(forKey: testKey)
        
        // Assert: Verify that retrieved token is nil
        XCTAssertNil(retrievedToken, "Retriveding a non existing token should return nil")
        
    }
    
    
    func testSaveTokenDuplicateEntryThrowsError() {
        
        // Arrange: save the first token
        XCTAssertNoThrow(try keychainManager.saveToken(testToken, forKey: testKey), "Initial token saving should be succssful")
        
        XCTAssertThrowsError(try keychainManager.saveToken(anotherTeskToken, forKey: testKey), "Saving a duplicate token should throw an error") {
            error in
            
            guard let keychainError = error as? KeychainManager.KeychainError else {
                XCTFail("Expcectd KeychainError but got \(type(of: error))")
                return
            }
            XCTAssertEqual(keychainError, KeychainManager.KeychainError.duplicateEntry, "Expected .duplicateEntry error but got \(keychainError)" )
        }
        
        let retrivedToken = keychainManager.getToken(forKey: testKey)
        XCTAssertEqual(retrivedToken, testToken, "The original token should still be present after the duplicate save attempt failed")
        
    }
    
//    func testSaveAndRetrivedEmptyToken() {
//        let emptyToken = ""
//
//        // Act & Assert: Save
//        XCTAssertNoThrow(try keychainManager.saveToken(emptyToken, forKey: testKey))
//
//        // Act: Retrieve
//        let retrivedToken = keychainManager.getToken(forKey: testKey)
//
//        // Assert
//        XCTAssertNotNil(retrivedToken)
//        XCTAssertEqual(retrivedToken, emptyToken, "Retrived  token should be an empty string")
//    }
    
}


// Override == using Equatable for value equaltiy checks
extension KeychainManager.KeychainError: @retroactive Equatable {
    
    public static func == (lhs: KeychainManager.KeychainError, rhs: KeychainManager.KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateEntry, .duplicateEntry):
            return true
        case (.unknown(let status1), .unknown(let status2)):
            return status1 == status2
        default:
            return false
        }
    }
}
