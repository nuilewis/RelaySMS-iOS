//
//  gRPCHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 25/06/2024.
//

import Foundation
import GRPC

class GRPCHandler {
    #if DEBUG
        private static var VAULT_GRPC = "vault.staging.smswithoutborders.com"
        private static var VAULT_PORT = 443

        private static var PUBLISHER_GRPC = "publisher.staging.smswithoutborders.com"
        private static var PUBLISHER_PORT = 443
    #else
        private static var VAULT_GRPC = "vault.smswithoutborders.com"
        private static var VAULT_PORT = 443
        
        private static var PUBLISHER_GRPC = "publisher.smswithoutborders.com"
        private static var PUBLISHER_PORT = 443
    #endif
    
    static func getChannelVault() -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: VAULT_GRPC, port: VAULT_PORT)
    }
    
    static func getChannelPublisher() -> ClientConnection {
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1, networkPreference: .best)
        return ClientConnection
            .usingPlatformAppropriateTLS(for: group)
            .connect(host: PUBLISHER_GRPC, port: PUBLISHER_PORT)
    }
}
