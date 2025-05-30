//
//  PlatformsEntityHandlers.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 15/01/2025.
//

import CoreData
import Foundation
import SwiftUICore

//struct DownloadContent {
//}

struct PlatformsEntityHandler {
    let context: NSManagedObjectContext

    // MARK: - CRUD Operations
    func putStoredPlatform(_ platform: Platform) {

        // Make sure platform name is not empty, as that will be used as the identitier
        guard !platform.name.isEmpty else {
            print("Error: Platform name cannot be empty for put operation")
            return
        }

        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "name == %@", platform.name)

        do {
            let existingEntity = try context.fetch(fetchRequest).first
            let entityToSave: PlatformsEntity

            if let existing = existingEntity {
                print("Updating existing platform with name: \(platform.name)")
                entityToSave = existing
            } else {
                print("Creating new platform with name: \(platform.name)")
                entityToSave = PlatformsEntity(context: context)
                entityToSave.name = platform.name
            }

            entityToSave.name = platform.name
            entityToSave.protocol_type = platform.protocolType
            entityToSave.service_type = platform.serviceType
            entityToSave.shortcode = platform.shortcode
            entityToSave.support_url_scheme = platform.supportUrlScheme
            entityToSave.image = platform.imageData

            try context.save()
            print("Successfully saved platform: \(platform.name)")

        } catch {
            print("Error saving platform (name: \(platform.name)): \(error)")
        }
    }
    func getAllPlatforms() -> [Platform] {
        print("Getting all platforms")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
            as NSFetchRequest<PlatformsEntity>

        do {
            let entities = try context.fetch(fetchRequest)
            if entities.isEmpty {
                print("No platforms found")
            } else {
                print("Successfully fetched \(entities.count) platforms")
            }

            return entities.compactMap { entity in
                try? Platform.fromEntity(entity)
            }
        } catch {
            print("Failed to fetch platforms: \(error)")
            return []
        }
    }

    func getPlatform(byName platformName: String) -> Platform? {

        guard !platformName.isEmpty else {
            print("Error: Platform name cannot be empty for fetch operation.")
            return nil
        }

        print("Getting stored platform with name \(platformName)")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", platformName)

        do {

            guard let entity = try context.fetch(fetchRequest).first else {
                print("No platform found with name: \(platformName)")
                return nil
            }

            return try Platform.fromEntity(entity)

        } catch {
            print(
                "Failed to fetch platform with name \(platformName): \(error)")
            return nil
        }
    }

    func deleteStoredPlatform(byName platformName: String) {
        guard !platformName.isEmpty else {
            print("Error: Platform name cannot be empty for delete operation.")
            return
        }

        print("Deleting platform with name : \(platformName)")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", platformName)

        do {
            guard let entityToDelete = try context.fetch(fetchRequest).first
            else {
                print(
                    "Platform with name '\(platformName)' not found. Unable to delete."
                )
                return
            }

            context.delete(entityToDelete)
            try context.save()
            print("Successfully deleted platform with name: \(platformName)")
        } catch {
            print("Error deleting platform with name \(platformName): \(error)")
        }
    }

    func deleteAllPlatforms() {
        print("Deleting all platforms...")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            PlatformsEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            try context.execute(batchDeleteRequest)
            print("Successfully deleted all platforms via batch delete.")
        } catch {
            print("Error deleting all platforms: \(error)")
        }
    }
}

// Simple model to handle a Platform entities

struct Platform: Identifiable {
    let name: String
    let protocolType: String
    let serviceType: String
    let shortcode: String
    let supportUrlScheme: Bool
    let imageData: Data?

    var id: String { name }

    init(
        name: String, protocolType: String, serviceType: String,
        shortcode: String, supportUrlScheme: Bool, imageData: Data?
    ) {
        self.name = name
        self.protocolType = protocolType
        self.serviceType = serviceType
        self.shortcode = shortcode
        self.supportUrlScheme = supportUrlScheme
        self.imageData = imageData
    }

    func copyWith(
        name: String? = nil,
        protocolType: String? = nil,
        serviceType: String? = nil,
        shortcode: String? = nil,
        supportUrlScheme: Bool? = nil,
        imageData: Data? = nil
    ) -> Platform {
        return Platform(
            name: name ?? self.name,
            protocolType: protocolType ?? self.protocolType,
            serviceType: serviceType ?? self.serviceType,
            shortcode: shortcode ?? self.shortcode,
            supportUrlScheme: supportUrlScheme ?? self.supportUrlScheme,
            imageData: imageData ?? self.imageData
        )
    }

    static func fromEntity(_ entity: PlatformsEntity) throws -> Platform {
        guard let entityName = entity.name, !entityName.isEmpty else {
            throw CustomError(
                message: "Invalid Entity: Platform name is nil or empty")
        }

        return Platform(
            name: entityName,
            protocolType: entity.protocol_type ?? "",
            serviceType: entity.service_type ?? "",
            shortcode: entity.shortcode ?? "",
            supportUrlScheme: entity.support_url_scheme,
            imageData: entity.image
        )
    }

}
