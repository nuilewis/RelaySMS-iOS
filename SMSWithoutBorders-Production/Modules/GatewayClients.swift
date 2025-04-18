//
//  GatewayClients.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import CoreData
import Foundation

class GatewayClients: Codable {
    public static var GATEWAY_CLIENT_URL = "https://gatewayserver.smswithoutborders.com/v3/clients"
    public static var DEFAULT_GATEWAY_CLIENT_MSISDN = "COM.AFKANERD.RELAY.DEFAULT_GATEWAY_CLIENT_MSISDN"

    var country: String
    var last_published_date: Int
    var msisdn: String
    var `operator`: String
    var operator_code: String
    var protocols: [String]
    var reliability: String

    init(
        country: String,
        last_published_date: Int,
        msisdn: String,
        operator _operator: String,
        operator_code: String,
        protocols: [String],
        reliability: String
    ) {
        self.country = country
        self.msisdn = msisdn
        self.operator = _operator
        self.operator_code = operator_code
        self.protocols = protocols
        self.reliability = reliability
        self.last_published_date = last_published_date
    }

    private static func fetch() async throws -> [GatewayClients] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: GATEWAY_CLIENT_URL)!)
        return try! JSONDecoder().decode([GatewayClients].self, from: data)
    }

    public static func refresh(context: NSManagedObjectContext) async throws {
        do {
            let gatewayClients = try await fetch()

            if !gatewayClients.isEmpty {
                //       try GatewayClients.clear(context: context, shouldSave: false)

                for defaultGatewayClient in gatewayClients {
                    let fetchRequest = GatewayClientsEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "msisdn == %@", defaultGatewayClient.msisdn)

                    await context.perform {

                        do {
                            let existingGatewayClients = try context.fetch(fetchRequest)
                            print(existingGatewayClients.count)

                            if let gatewayClient = existingGatewayClients.first {
                                gatewayClient.country = defaultGatewayClient.country
                                gatewayClient.lastPublishedDate = Int32(defaultGatewayClient.last_published_date)
                                gatewayClient.operatorName = defaultGatewayClient.operator
                                gatewayClient.operatorCode = defaultGatewayClient.operator_code
                                gatewayClient.protocols = defaultGatewayClient.protocols.joined(separator: ",")
                                gatewayClient.reliability = defaultGatewayClient.reliability
                            } else {
                                let gatewayClient = GatewayClientsEntity(context: context)
                                gatewayClient.country = defaultGatewayClient.country
                                gatewayClient.lastPublishedDate = Int32(defaultGatewayClient.last_published_date)
                                gatewayClient.msisdn = defaultGatewayClient.msisdn
                                gatewayClient.operatorName = defaultGatewayClient.operator
                                gatewayClient.operatorCode = defaultGatewayClient.operator_code
                                gatewayClient.protocols = defaultGatewayClient.protocols.joined(separator: ",")
                                gatewayClient.reliability = defaultGatewayClient.reliability
                            }
                        } catch {
                            print(error)
                        }
                    }

                }

                configureDefaults()

                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        print("Failed to save Gateway client: \(error) \(error.localizedDescription)")
                    }
                }
            } else {
                print("Going with defaults....")
                try GatewayClients.addDefaultGatewayClientsIfNeeded(context: context)
            }
        } catch {
            print("Error refreshing gateway clients: \(error)")
            try GatewayClients.addDefaultGatewayClientsIfNeeded(context: context)
        }
    }

    static func configureDefaults() {
        let currentDefault = UserDefaults.standard.object(forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String ?? ""

        if currentDefault.isEmpty {
            let defaultGatewayClients = GatewayClients.getDefaultGatewayClients()
            print("configuring default: \(defaultGatewayClients.first?.msisdn)")
            UserDefaults.standard.set(defaultGatewayClients[0].msisdn, forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        } else {
            print("Current default: \(currentDefault)")
        }
    }

    static func clear(context: NSManagedObjectContext, shouldSave: Bool = true) throws {
        print("Clearing GatewayClients...")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GatewayClientsEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)  // Use batch delete for efficiency

        deleteRequest.resultType = .resultTypeCount  // Or .resultTypeObjectIDs if you need object IDs

        do {
            try context.execute(deleteRequest)
            //            try context.save()
        } catch {
            print("Error clearing GatewayClients: \(error)")
            context.rollback()
            throw error  // Re-throw the error after rollback
        }
    }

    public static func getDefaultGatewayClients() -> [GatewayClients] {
        return [
            GatewayClients(
                country: "Nigeria",
                last_published_date: 0,
                msisdn: "+2348131498393",
                operator: "MTN Nigeria",
                operator_code: "62130",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),

            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237679466332",
                operator: "MTN Cameroon",
                operator_code: "62401",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),

            GatewayClients(
                country: "Cameroon",
                last_published_date: 0,
                msisdn: "+237690826242",
                operator: "Orange Cameroon",
                operator_code: "62402",
                protocols: ["https", "smtp", "ftp"],
                reliability: ""),
        ]
    }

    public static func addDefaultGatewayClientsIfNeeded(context: NSManagedObjectContext) throws {
        let defaultGatewayClients = GatewayClients.getDefaultGatewayClients()

        for defaultGatewayClient in defaultGatewayClients {
            // Check if a GatewayClientsEntity with this MSISDN already exists
            let fetchRequest = NSFetchRequest<GatewayClientsEntity>(entityName: "GatewayClientsEntity")
            fetchRequest.predicate = NSPredicate(format: "msisdn == %@", defaultGatewayClient.msisdn)

            let existingClients = try context.fetch(fetchRequest)

            if existingClients.isEmpty {  // Only add if it doesn't already exist
                let gatewayClient = GatewayClientsEntity(context: context)
                gatewayClient.country = defaultGatewayClient.country
                gatewayClient.lastPublishedDate = Int32(defaultGatewayClient.last_published_date)
                gatewayClient.msisdn = defaultGatewayClient.msisdn
                gatewayClient.operatorName = defaultGatewayClient.operator
                gatewayClient.operatorCode = defaultGatewayClient.operator_code
                gatewayClient.protocols = defaultGatewayClient.protocols.joined(separator: ",")
                gatewayClient.reliability = defaultGatewayClient.reliability

                if OperatorHandlers.isMatchingOperatorCode(operatorCode: gatewayClient.operatorCode!) {
                    // ... (Your existing logic for setting the returningGatewayClient)
                }
            } else {
                print("Gateway client with MSISDN \(defaultGatewayClient.msisdn) already exists. Skipping.")
            }
        }

        do {
            print("Saving default Gateway clients (if any were added)")
            try context.save()
            configureDefaults()
            print("Ended the default matter")
        } catch {
            print("Error saving Gateway client!: \(error)")
            throw error  // Re-throw the error
        }
    }


    public static func addGatewayClient(context: NSManagedObjectContext, client: GatewayClients) throws {
        // Add a new instance of the client in the database
        let gatewayClientEntity: GatewayClientsEntity = GatewayClientsEntity(context: context)
        gatewayClientEntity.country = client.country
        gatewayClientEntity.lastPublishedDate = Int32(client.last_published_date)
        gatewayClientEntity.msisdn = client.msisdn
        gatewayClientEntity.operatorName = client.operator
        gatewayClientEntity.operatorCode = client.operator_code
        gatewayClientEntity.protocols = client.protocols.joined(separator: ",")
        gatewayClientEntity.reliability = client.reliability

        do {
            print("Saving or Updating Gateway clients with msisdn: \(client.msisdn)")
            try context.save()
            configureDefaults()
            print("Ended the default matter")
        } catch {
            print("Error saving Gateway client!: \(error)")
            throw error  // Re-throw the error
        }
    }


    public static func updateGatewayClient(context: NSManagedObjectContext, oldClientMsisdn: String, newClient: GatewayClients) throws {
        // Fetch and check if gatewaycleint already exist
        let fetchRequest = GatewayClientsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "msisdn == %@", oldClientMsisdn)

        let results = try context.fetch(fetchRequest)

        guard let existingClientEntity = results.first else {
            print("Error updating: Client with MSISDN \(oldClientMsisdn) not found")
            throw CustomError(message: "Client to update not found")
        }

        // An existing client exist, update that
        existingClientEntity.country = newClient.country
        existingClientEntity.lastPublishedDate = Int32(newClient.last_published_date)
        existingClientEntity.msisdn = newClient.msisdn
        existingClientEntity.operatorName = newClient.operator
        existingClientEntity.operatorCode = newClient.operator_code
        existingClientEntity.protocols = newClient.protocols.joined(separator: ",")
        existingClientEntity.reliability = newClient.reliability


        if context.hasChanges {
            do {
                print("Updating Gateway clients with msisdn: \(newClient.msisdn)")
                try context.save()
                print("Successfully saved updated client: \(newClient.msisdn)")
                configureDefaults()
            } catch {
                print("Error updating Gateway client!: \(error)")
                context.rollback()
                throw error  // Re-throw the error
            }
        } else {
            print("No changes detected in context for client \(oldClientMsisdn). Skipping save.")
        }

    }


    public static func deleteGatewayClient(context: NSManagedObjectContext, client: GatewayClients) throws {
        // Fetch and check if gatewayclient already exist
        let fetchRequest: NSFetchRequest = NSFetchRequest<GatewayClientsEntity>(entityName: "GatewayClientsEntity")
        fetchRequest.predicate = NSPredicate(format: "msisdn == %@", client.msisdn)
        let existingClientEntity: GatewayClientsEntity? = try context.fetch(fetchRequest).first

        if existingClientEntity != nil {
            context.delete(existingClientEntity!)
            do {
                print("Deleting Gateway clients with msisdn: \(client.msisdn)")
                try context.save()
                configureDefaults()
                print("Ended the default matter")
            } catch {
                print("Error deleting Gateway client!: \(error)")
                throw error  // Re-throw the error
            }
        } else {
            throw CustomError(message: "Unable to delete Gateway client; Gateway client not found!")
        }
    }


    public static func fromEntity(entity: GatewayClientsEntity) -> GatewayClients {

        var protocols: [String] = []

        if entity.protocols != nil {
            if !entity.protocols!.isEmpty {
                protocols = entity.protocols!.split(separator: ",").makeIterator().map(String.init)
            }
        }

        return GatewayClients(
            country: entity.country ?? "",
            last_published_date: Int(entity.lastPublishedDate),
            msisdn: entity.msisdn ?? "",
            operator: entity.operatorName ?? "",
            operator_code: entity.operatorCode ?? "",
            protocols: protocols,
            reliability: entity.reliability ?? ""
        )

    }
}


extension GatewayClientsEntity {
    func isDefaultClient() -> Bool {
        guard let msisdn = self.msisdn else { return false }
        // Check against hardcoded Twilio number
        if msisdn == "+15024439537" {
            return true
        }

        let defaultList = GatewayClients.getDefaultGatewayClients()
        return defaultList.contains { $0.msisdn == msisdn }
    }
}
