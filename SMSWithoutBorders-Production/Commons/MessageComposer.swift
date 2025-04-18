//
//  MessageComposer.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/08/2024.
//

import Foundation
import SwobDoubleRatchet
import CryptoKit
import CoreData

struct MessageComposer {
    
    var SK: [UInt8]?
    var keystoreAlias: String
    var AD: [UInt8]
    var state = States()
    var deviceID: [UInt8]?
    var context: NSManagedObjectContext
    var useDeviceID: Bool
    var languageCode: [UInt8]

    init(SK: [UInt8]?, 
         AD: [UInt8],
         peerDhPubKey: Curve25519.KeyAgreement.PublicKey?,
         keystoreAlias: String,
         deviceID: [UInt8]? = nil,
         context: NSManagedObjectContext,
         useDeviceID: Bool = true) throws {
        self.SK = SK
        self.keystoreAlias = keystoreAlias
        self.AD = AD
        self.deviceID = deviceID
        self.context = context
        self.useDeviceID = useDeviceID
        self.languageCode = Array(LanguagePreferencesManager.getStoredLanguageCode().utf8)


        let fetchStates = try fetchStates()
//        print("AD in message composer: \(AD.toBase64())")
        if fetchStates == nil {
            print("[+] Initializing states...")
            self.state = States()
            try Ratchet.aliceInit(
                state: self.state,
                SK: self.SK!,
                bobDhPubKey: peerDhPubKey!,
                keystoreAlias: self.keystoreAlias)
        } else {
            print("Fetched state: \(fetchStates!.data?.base64EncodedString())")
//            print(try deserialize(data: fetchStates!.data!))
            self.state = try States.deserialize(data: fetchStates!.data!)!
        }
    }
    
    public static func hasStates(context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<StatesEntity> = StatesEntity.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            return result.count > 0
        } catch {
            return false
        }
    }
    
    private func fetchStates() throws -> StatesEntity? {
        let fetchRequest: NSFetchRequest<StatesEntity> = StatesEntity.fetchRequest()
        do {
            let result = try self.context.fetch(fetchRequest)
            if result.count > 0 {
                let stateEntity = result[0] as NSManagedObject as? StatesEntity
                return stateEntity
            }
        } catch {
            print("Error fetching StatesEntity: \(error)")
            throw error
        }
        return nil
    }
    
    private func saveState() throws {
        do {
            try Vault.resetStates(context: self.context)
            
            let statesEntity = StatesEntity(context: context)
            statesEntity.data = self.state.serialized()
            try context.save()
            
            print("Stored state: \(statesEntity.data?.base64EncodedString())")
            
        } catch {
            print("Error in saving states....")
            throw error
        }
    }
    
    public func emailComposer(platform_letter: UInt8, from: String, to: String, cc: String, bcc: String,
                              subject: String,
                              body: String) throws -> String {
        let content = "\(from):\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func emailComposerV1(platform_letter: UInt8, from: String, to: String, cc: String, bcc: String,
                              subject: String,
                              body: String,
                              accessToken: String,
                              refreshToken: String
    ) throws -> String {
        let content = "\(from):\(to):\(cc):\(bcc):\(subject):\(body):[\(accessToken):\(refreshToken)]".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func textComposer(platform_letter: UInt8,
                             sender: String, text: String) throws -> String {
        let content = "\(sender):\(text)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    
    public func textComposerV1(platform_letter: UInt8,
                             sender: String, text: String,           accessToken: String,
                               refreshToken: String) throws -> String {
        let content = "\(sender):\(text):[\(accessToken):\(refreshToken)]".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func messageComposer(
        platform_letter: UInt8,
        sender: String,
        receiver: String,
        message: String
    ) throws -> String {
        let content = "\(sender):\(receiver):\(message)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func messageComposerV1(
        platform_letter: UInt8,
        sender: String,
        receiver: String,
        message: String,
        accessToken: String,
        refreshToken: String
    ) throws -> String {
            
        let content = "\(sender):\(receiver):\(message):[\(accessToken):\(refreshToken)]".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    
    public func bridgeEmailComposer(
        to: String,
        cc: String,
        bcc: String,
        subject: String,
        body: String,
        saveState: Bool = true
    ) throws -> Data {
        let content = "\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
        if(saveState) {
            try self.saveState()
        }
        return formatBridgeTransmission(header: header, cipherText: cipherText)
    }
    
    // Helper methods to format payload
    private func formatBridgeTransmission(header: HEADERS, cipherText: [UInt8]) -> Data {
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 4)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var encryptedContentPayload = Data()
        encryptedContentPayload.append(bytesHeaderLen)
        encryptedContentPayload.append(sHeader)
        encryptedContentPayload.append(Data(cipherText))
        
        return encryptedContentPayload
    }

    private func formatTransmission(header: HEADERS,
                                    cipherText: [UInt8],
                                    platform_letter: UInt8) -> String {
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 4)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var encryptedContentPayload = Data()
        encryptedContentPayload.append(bytesHeaderLen)
        encryptedContentPayload.append(sHeader)
        encryptedContentPayload.append(Data(cipherText))
        
        var payloadLen = Data(count: 4)
        payloadLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(encryptedContentPayload.count).littleEndian, as: UInt32.self)
        }
        
        var data = Data()
        data.append(payloadLen)
        data.append(platform_letter)
        data.append(encryptedContentPayload)
        if useDeviceID && deviceID != nil {
            data.append(Data(deviceID!))
        }
        print("Sending: \(data.base64EncodedString())")

        return data.base64EncodedString()
    }
    
    
    private func formatTransmissionV1(header: HEADERS,
                                    cipherText: [UInt8],
                                    platform_letter: UInt8) -> String {
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 2)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var bytesVersionMarker = Data(Array("1".utf8))
        bytesVersionMarker.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(1).littleEndian, as: UInt32.self)
        }
        
        
        var bytesDeviceIdLength = Data(count: 1)
        bytesDeviceIdLength.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(1).littleEndian, as: UInt32.self)
        }
        
        
        var encryptedContentPayload = Data()
        encryptedContentPayload.append(bytesHeaderLen)
        encryptedContentPayload.append(sHeader)
        encryptedContentPayload.append(Data(cipherText))
        
        
        var payloadLen = Data(count: 2 )
        payloadLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(encryptedContentPayload.count).littleEndian, as: UInt32.self)
        }
        
        // Data to send
        /// Visual Representation of data
        /// ```plaintext
        /// +----------------+-------------------+------------------+--------------------+-----------------+-----------------+---------------+
        /// | Version Marker | Ciphertext Length | Device ID Length | Platform shortcode | Ciphertext      | Device ID       | Language Code |
        /// | (1 byte)       | (2 bytes)         | (1 byte)         | (1 byte)           | (Variable size) | (Variable size) | (2 bytes)     |
        /// +----------------+-------------------+------------------+--------------------+-----------------+-----------------+---------------+
        /// ```
        
        var data = Data()
        //Version
        data.append(bytesVersionMarker)
        //Payload length
        data.append(payloadLen)
        //Device ID length
        data.append(bytesDeviceIdLength)
        //Platform shortcode
        data.append(platform_letter)
        //Encrypted message content/Ciphertext/payload
        data.append(encryptedContentPayload)
        if useDeviceID && deviceID != nil {
            data.append(Data(deviceID!))
        }
        //LanguageCode
        data.append(Data(languageCode))
        print("Sending: \(data.base64EncodedString())")
        return data.base64EncodedString()
    }
    
    
    
    public func decryptBridgeMessage(payload: [UInt8]) throws -> [UInt8]? {
        let lenHeader = Data(payload[0..<4]).withUnsafeBytes { $0.load(as: Int32.self) }.littleEndian
        guard let header = HEADERS.deserialize(serializedData: Data(payload[4..<(4+Int(lenHeader))])) else {
            print("Issue constructing header...")
            return nil
        }
        let cipherText = Array(payload[(4+Int(lenHeader))..<payload.count])
        
        let text = try Ratchet.decrypt(
            state: self.state,
            header: header,
            cipherText: cipherText,
            AD: self.AD,
            keystoreAlias: self.keystoreAlias
        )
        try self.saveState()
//        return String(decoding: text, as: Unicode.UTF8.self)
        return text
    }
}
