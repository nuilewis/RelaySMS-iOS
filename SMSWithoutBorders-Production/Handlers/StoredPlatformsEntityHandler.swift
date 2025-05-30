//
//  StoredPlatformsEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/05/2025.
//

import CoreData

struct StoredPlatformsEntityHandler {
    let context: NSManagedObjectContext

    // MARK: - CRUD Operations
    func putStoredPlatform(platformAccount: StoredPlatform) {

        guard !platformAccount.id.isEmpty else {
            print(
                "Error: StoredPlatform ID cannot be empty for upsert operation."
            )
            return
        }

        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "id == %@", platformAccount.id)
        fetchRequest.fetchLimit = 1

        do {
            let existingEntity = try context.fetch(fetchRequest).first
            let entityToSave: StoredPlatformsEntity
            
            if let existing = existingEntity {
                print("Updating existing stored platform with ID: \(platformAccount.id)")
                entityToSave = existing
            } else {
                print("Creating new stored platform with ID: \(platformAccount.id)")
                entityToSave = StoredPlatformsEntity(context: context)
                entityToSave.id = platformAccount.id
            }

            entityToSave.name = platformAccount.name
            entityToSave.account = platformAccount.account
            entityToSave.access_token = platformAccount.accessToken
            entityToSave.refresh_token = platformAccount.refreshToken

            try context.save()
            print("Successfully saved stored platform: \(platformAccount.name) (ID: \(platformAccount.id))")

        } catch {
            print(
                "Error saving stored platform (ID: \(platformAccount.id)): \(error)"
            )
        }

    }
    func getAllStoredPlatforms() -> [StoredPlatform] {
        print("Getting all stored platform accounts")
        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        do {
            let entities: [StoredPlatformsEntity] = try context.fetch(
                fetchRequest)

            if entities.isEmpty {
                print("No stored platform accounts found")
            } else {
                print(
                    "Successfully fetched \(entities.count) stored platform accounts."
                )
            }

            return entities.compactMap { entity in
                //try? StoredPlatform.fromEntity(entity)
                do {
                    return try StoredPlatform.fromEntity(entity)
                } catch {
                    let entityId = entity.id ?? "Unknown"
                    print(
                        "Failed to map StoredPlatformsEntity to StoredPlatform (Entity ID: \(entityId)): \(error)"
                    )
                    return nil
                }
            }

        } catch {
            print("Failed to fetch stored platform accounts: \(error)")
            return []
        }
    }

    func getStoredPlatform(byId platformId: String) -> StoredPlatform? {
        
        guard !platformId.isEmpty else {
            print("Error: Platform ID cannot be empty for fetch operation.")
            return nil
        }
        print("Getting stored platform with id \(platformId)")
        
        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", platformId)
        fetchRequest.fetchLimit = 1
        
        do {
            
            guard let entity = try context.fetch(fetchRequest).first else {
                print("No stored platform account found for platform with ID: \(platformId)")
                return nil
            }
            
            return try StoredPlatform.fromEntity(entity)
        } catch {
            print("Failed to fetch or map stored platform account (ID: \(platformId)): \(error)")
            return nil
        }
    }
    
    func deleteStoredPlatform(byId platformId: String) {
        
        guard !platformId.isEmpty else {
            print("Error: Platform ID cannot be empty for delete operation.")
            return
        }
        
        print("Deleting stored platform with ID: \(platformId)")
        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", platformId)
        fetchRequest.fetchLimit = 1

        do {
            
            guard let entityToDelete = try context.fetch(fetchRequest).first else {
                print("Stored platform with ID '\(platformId)' not found. Unable to delete.")
                return
            }
            
            context.delete(entityToDelete)
            try context.save()
            print("Successfully deleted stored platform with ID: \(platformId)")
            
        } catch {
            print("Error deleting stored platform account (ID: \(platformId)): \(error)")
        }
    }


    func deleteAllStoredPlatformAccounts() {
        print("Deleting all platform accounts....")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            StoredPlatformsEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            try context.execute(batchDeleteRequest)
            print("Successfully deleted all stored platform accounts via batch delete.")
        } catch {
            print("Error deleting all stored platform accounts via batch delete: \(error)")
        }
    }
}

// Simple model to handle a Platform Account entities
struct StoredPlatform: Identifiable {
    let id: String
    let name: String
    let account: String
    let accessToken: String?
    let refreshToken: String?
    //let idToken: String?

    init(
        id: String, name: String, account: String, accessToken: String?,
        refreshToken: String?
    ) {
        self.id = id
        self.name = name
        self.account = account
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func copyWith(
        name: String?, account: String?, accessToken: String?,
        refreshToken: String?, idToken: String?
    ) -> StoredPlatform {
        return StoredPlatform(
            id: self.id,
            name: name ?? self.name,
            account: account ?? self.account,
            accessToken: accessToken ?? self.accessToken,
            refreshToken: refreshToken ?? self.refreshToken
        )
    }

    static func fromEntity(_ entity: StoredPlatformsEntity) throws
        -> StoredPlatform
    {
        guard let entityId = entity.id, !entityId.isEmpty else {
            throw CustomError(message: "Invalid Entity: Entity ID is nil")
        }

        return StoredPlatform(
            id: entityId,
            name: entity.name ?? "",
            account: entity.account ?? "",
            accessToken: entity.access_token,
            refreshToken: entity.refresh_token
        )
    }

}
