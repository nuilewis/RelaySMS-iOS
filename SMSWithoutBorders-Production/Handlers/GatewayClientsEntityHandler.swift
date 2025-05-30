//
//  GatewayClientsEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 29/05/2025.
//

import Foundation
import CoreData

struct GatewayClientsEntityHandler {
    let context: NSManagedObjectContext

    // MARK: - CRUD Operations
    func putGatewayClient(_ gatewayClient: GatewayClient) {
        guard !gatewayClient.msisdn.isEmpty else {
            print("Error: GatewayClient MSISDN cannot be empty for upsert operation.")
            return
        }

        let fetchRequest: NSFetchRequest<GatewayClientsEntity> = GatewayClientsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "msisdn == %@", gatewayClient.msisdn)
        fetchRequest.fetchLimit = 1

        do {
            let exsitingEntity = try context.fetch(fetchRequest).first
            let entityToSave: GatewayClientsEntity
            
            if let existing = exsitingEntity {
                print("Updating existing GatewayClient with MSISDN: \(gatewayClient.msisdn)")
                entityToSave = existing
            } else {
                print("Creating new GatewayClient with MSISDN: \(gatewayClient.msisdn)")
                entityToSave = GatewayClientsEntity(context: context)
                entityToSave.msisdn = gatewayClient.msisdn
            }

            entityToSave.country = gatewayClient.country
            if let date = gatewayClient.lastPublishedDate {
                entityToSave.lastPublishedDate = Int32(date.timeIntervalSince1970)
            } else {
                // How to represent 'no date'? 0 is common for timestamps.
                // Ensure Int32 is sufficient (Year 2038 problem for 32-bit signed Unix time).
                // If your app deals with dates beyond ~2038, use Int64 for lastPublishedDate in Core Data.
                entityToSave.lastPublishedDate = 0
            }
            entityToSave.operatorCode = gatewayClient.operatorCode
            entityToSave.operatorName = gatewayClient.operatorName
            entityToSave.protocols = gatewayClient.protocols
            entityToSave.reliability = gatewayClient.reliability

            try context.save()
            print("Successfully saved GatewayClient: \(gatewayClient.operatorName) (MSISDN: \(gatewayClient.msisdn))")
        } catch {
            print("Error saving GatewayClient (MSISDN: \(gatewayClient.msisdn)): \(error)")
        }
    }

    /// Fetches all GatewayClients from Core Data.
    func getAllGatewayClients() -> [GatewayClient] {
        print("Getting all GatewayClients")
        let fetchRequest: NSFetchRequest<GatewayClientsEntity> = GatewayClientsEntity.fetchRequest()

        do {
            let entities = try context.fetch(fetchRequest)
            if entities.isEmpty {
                print("No GatewayClients found.")
            } else {
                print("Successfully fetched \(entities.count) GatewayClients.")
            }

            return entities.compactMap { entity in
                do {
                    return try GatewayClient.fromEntity(entity)
                } catch {
                    let entityMsisdn = entity.msisdn ?? "Unknown"
                    print("Failed to map GatewayClientsEntity to GatewayClient (MSISDN: \(entityMsisdn)): \(error)")
                    return nil
                }
            }
        } catch {
            print("Failed to fetch GatewayClients: \(error)")
            return []
        }
    }

    /// Fetches a specific GatewayClient by its MSISDN.
    func getGatewayClient(byMsisdn msisdn: String) -> GatewayClient? {
        guard !msisdn.isEmpty else {
            print("Error: MSISDN cannot be empty for fetch operation.")
            return nil
        }
        print("Getting GatewayClient with MSISDN: \(msisdn)")
        let fetchRequest: NSFetchRequest<GatewayClientsEntity> = GatewayClientsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "msisdn == %@", msisdn)
        fetchRequest.fetchLimit = 1

        do {
            guard let entity = try context.fetch(fetchRequest).first else {
                print("No GatewayClient found with MSISDN: \(msisdn)")
                return nil
            }
            return try GatewayClient.fromEntity(entity)
        } catch {
            print("Failed to fetch or map GatewayClient (MSISDN: \(msisdn)): \(error)")
            return nil
        }
    }

    /// Deletes a GatewayClient by its MSISDN.
    func deleteGatewayClient(byMsisdn msisdn: String) {
        guard !msisdn.isEmpty else {
            print("Error: MSISDN cannot be empty for delete operation.")
            return
        }
        print("Deleting GatewayClient with MSISDN: \(msisdn)")
        let fetchRequest: NSFetchRequest<GatewayClientsEntity> = GatewayClientsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "msisdn == %@", msisdn)
        fetchRequest.fetchLimit = 1

        do {
            guard let entityToDelete = try context.fetch(fetchRequest).first else {
                print("GatewayClient with MSISDN '\(msisdn)' not found. Unable to delete.")
                return
            }
            context.delete(entityToDelete)
            try context.save()
            print("Successfully deleted GatewayClient with MSISDN: \(msisdn)")
        } catch {
            print("Error deleting GatewayClient (MSISDN: \(msisdn)): \(error)")
        }
    }

    /// Deletes all GatewayClients from Core Data using NSBatchDeleteRequest.
    func deleteAllGatewayClients() {
        print("Deleting all GatewayClients...")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = GatewayClientsEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            try context.execute(batchDeleteRequest)
            print("Successfully deleted all GatewayClients via batch delete.")
        } catch {
            print("Error deleting all GatewayClients via batch delete: \(error)")
        }
    }
}


import Foundation
import CoreData

struct GatewayClient: Identifiable {
    // msisdn is the primary identifier
    let msisdn: String
    let country: String
    let lastPublishedDate: Date? // Mapped from Integer 32 timestamp
    let operatorCode: String
    let operatorName: String
    let protocols: String
    let reliability: String

    // Conformance to Identifiable
    var id: String { msisdn }

    init(msisdn: String,
         country: String,
         lastPublishedDate: Date?,
         operatorCode: String,
         operatorName: String,
         protocols: String,
         reliability: String) {
        self.msisdn = msisdn
        self.country = country
        self.lastPublishedDate = lastPublishedDate
        self.operatorCode = operatorCode
        self.operatorName = operatorName
        self.protocols = protocols
        self.reliability = reliability
    }

    static func fromEntity(_ entity: GatewayClientsEntity) throws -> GatewayClient {
        guard let entityMsisdn = entity.msisdn, !entityMsisdn.isEmpty else {
            throw CustomError(message: "Invalid GatewayClientsEntity: MSISDN is nil or empty.")
        }

        let publicationDate: Date?
        if entity.lastPublishedDate != 0 {
            publicationDate = Date(timeIntervalSince1970: TimeInterval(entity.lastPublishedDate))
        } else {
            publicationDate = nil
        }

        return GatewayClient(
            msisdn: entityMsisdn,
            country: entity.country ?? "",
            lastPublishedDate: publicationDate,
            operatorCode: entity.operatorCode ?? "",
            operatorName: entity.operatorName ?? "",
            protocols: entity.protocols ?? "", // If this should be a list, parse it here
            reliability: entity.reliability ?? ""
        )
    }


    func copyWith(
        country: String? = nil,
        lastPublishedDate: Date?? = nil, // Use Date?? to differentiate between "no change" and "set to nil"
        operatorCode: String? = nil,
        operatorName: String? = nil,
        protocols: String? = nil,
        reliability: String? = nil
    ) -> GatewayClient {
        return GatewayClient(
            msisdn: self.msisdn,
            country: country ?? self.country,
            lastPublishedDate: lastPublishedDate ?? self.lastPublishedDate,
            operatorCode: operatorCode ?? self.operatorCode,
            operatorName: operatorName ?? self.operatorName,
            protocols: protocols ?? self.protocols,
            reliability: reliability ?? self.reliability
        )
    }
}
