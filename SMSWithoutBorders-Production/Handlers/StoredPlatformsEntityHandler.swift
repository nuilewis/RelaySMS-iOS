//
//  StoredPlatformsEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/05/2025.
//

import CoreData

// MARK: - Stored Platform Account
// Simple model to handle a Platform Account entities
struct StoredPlatform: Identifiable {
    let id: String
    let name: String
    let account: String
    let isStoredOnDevice: Bool
    let accessToken: String?
    let refreshToken: String?
    //let idToken: String?

    init(
        id: String, name: String,
        account: String,
        isStoredOnDevice: Bool,
        accessToken: String?,
        refreshToken: String?
    ) {
        self.id = id
        self.name = name
        self.account = account
        self.isStoredOnDevice = isStoredOnDevice
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func copyWith(
        name: String?,
        account: String?,
        isStoredOnDevice: Bool?,
        accessToken: String?,
        refreshToken: String?, idToken: String?
    ) -> StoredPlatform {
        return StoredPlatform(
            id: self.id,
            name: name ?? self.name,
            account: account ?? self.account,
            isStoredOnDevice: isStoredOnDevice ?? self.isStoredOnDevice,
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

        // TODO: Probably do the decryption here

        return StoredPlatform(
            id: entityId,
            name: entity.name ?? "",
            account: entity.account ?? "",
            isStoredOnDevice: entity.is_stored_on_device,
            accessToken: entity.access_token,
            refreshToken: entity.refresh_token
        )
    }

}

extension StoredPlatform {
    var tokensExists: Bool {
        if let aToken = accessToken, let rToken = refreshToken {
            return !aToken.isEmpty && !rToken.isEmpty
        } else {
            return false
        }
    }
    
    var isMissing: Bool {
      return  self.isStoredOnDevice && !self.tokensExists
    }
}

// MARK: - StoredPlatformsEntityHandler
struct StoredPlatformsEntityHandler {
    let context: NSManagedObjectContext
    func putStoredPlatform(platformAccount: StoredPlatform) throws {

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

        do {
            let existingEntity = try context.fetch(fetchRequest).first
            let entityToSave: StoredPlatformsEntity

            if let existing = existingEntity {
                print(
                    "Updating existing stored platform with ID: \(platformAccount.id)"
                )
                entityToSave = existing
            } else {
                print(
                    "Creating new stored platform with ID: \(platformAccount.id)"
                )
                entityToSave = StoredPlatformsEntity(context: context)
                entityToSave.id = platformAccount.id
            }

            entityToSave.name = platformAccount.name
            entityToSave.account = platformAccount.account
            entityToSave.is_stored_on_device = platformAccount.isStoredOnDevice
            if let icomingAccessToken = platformAccount.accessToken, !icomingAccessToken.isEmpty {
                entityToSave.access_token = platformAccount.accessToken
            }
            if let icomingRefreshToken = platformAccount.refreshToken, !icomingRefreshToken.isEmpty {
                entityToSave.refresh_token = platformAccount.refreshToken
            }

            try context.save()
            print(
                "Successfully saved stored platform: \(platformAccount.name) (ID: \(platformAccount.id))"
            )

        } catch {
            print(
                "Error saving stored platform (ID: \(platformAccount.id)): \(error)"
            )
            throw error
        }

    }
    func getAllStoredPlatforms() throws -> [StoredPlatform] {
        //print("Getting all stored platform accounts")
        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
        StoredPlatformsEntity.fetchRequest() as NSFetchRequest<StoredPlatformsEntity>
        do {
            let entities = try context.fetch(
                fetchRequest)

            if entities.isEmpty {
                print("No stored platform accounts found")
            } else {
                print(
                    "Successfully fetched \(entities.count) stored platform accounts."
                )
            }

            return entities.compactMap { entity in
                try? StoredPlatform.fromEntity(entity)
//                do {
//                    return try StoredPlatform.fromEntity(entity)
//                } catch {
//                    let entityId = entity.id ?? "Unknown"
//                    print(
//                        "Failed to map StoredPlatformsEntity to StoredPlatform (Entity ID: \(entityId)): \(error)"
//                    )
//                    return nil
//                }
            }

        } catch {
            print("Failed to fetch stored platform accounts: \(error)")
            throw error
        }
    }

    func getStoredPlatform(byId platformId: String) throws -> StoredPlatform? {

        guard !platformId.isEmpty else {
            print("Error: Platform ID cannot be empty for fetch operation.")
            return nil
        }
        //print("Getting stored platform with id \(platformId)")

        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", platformId)
        fetchRequest.fetchLimit = 1

        do {
            guard let entity = try context.fetch(fetchRequest).first else {
                print(
                    "No stored platform account found for platform with ID: \(platformId)"
                )
                return nil
            }

            return try StoredPlatform.fromEntity(entity)
        } catch {
            print(
                "Failed to fetch or map stored platform account (ID: \(platformId)): \(error)"
            )
            throw error
        }
    }

    func deleteStoredPlatform(byId platformId: String) throws {
        guard !platformId.isEmpty else {
            print("Error: Platform ID cannot be empty for delete operation.")
            return
        }

        //print("Deleting stored platform with ID: \(platformId)")
        let fetchRequest: NSFetchRequest<StoredPlatformsEntity> =
            StoredPlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", platformId)
        fetchRequest.fetchLimit = 1

        do {
            guard let entityToDelete = try context.fetch(fetchRequest).first
            else {
                print(
                    "Stored platform with ID '\(platformId)' not found. Unable to delete."
                )
                return
            }

            context.delete(entityToDelete)
            try context.save()
            print("Successfully deleted stored platform with ID: \(platformId)")

        } catch {
            print(
                "Error deleting stored platform account (ID: \(platformId)): \(error)"
            )
            throw error
        }
    }

    func deleteAllStoredPlatformAccounts() throws {
        print("Deleting all platform accounts....")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            StoredPlatformsEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            try context.execute(batchDeleteRequest)
            print(
                "Successfully deleted all stored platform accounts via batch delete."
            )
        } catch {
            print(
                "Error deleting all stored platform accounts via batch delete: \(error)"
            )
            context.rollback()
            throw error
        }
    }
}

// MARK: - StoredPlatform Account Store

class StoredPlatformStore: ObservableObject {
    @Published var storedPlatforms: [StoredPlatform] = []
    @Published var missingPlatforms: [StoredPlatform] = []
    @Published var publishablePlatforms: [StoredPlatform] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let handler: StoredPlatformsEntityHandler
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.handler = StoredPlatformsEntityHandler(context: context)
        
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) {
            [weak self] _ in
            self?.getStoredPlatforms()
        }
        getStoredPlatforms()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getStoredPlatforms() {
        print("[StoredPlatformStore]: Getting stored platforms...")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        context.performAndWait {
            do {
                let fetchedStoredPlatforms = try self.handler
                    .getAllStoredPlatforms()
                DispatchQueue.main.async {
                    self.storedPlatforms = fetchedStoredPlatforms
                    self.isLoading = false
                    
                    // Filter for missing and publishable platforms
                    self.missingPlatforms.removeAll()
                    self.publishablePlatforms.removeAll()
                    for platform in self.storedPlatforms {
                        if platform.isMissing {
                            self.missingPlatforms.append(platform)
                        } else {
                            self.publishablePlatforms.append(platform)
                        }
                    }
                    
                    print(
                        "[StoredPlatformStore]: Loaded \(self.storedPlatforms.count) stored platforms."
                    )
                    print(
                        "[StoredPlatformStore]: \(self.missingPlatforms.count) Missing stored platforms."
                    )
                    print(
                        "[StoredPlatformStore]: \(self.missingPlatforms) Missing stored platforms."
                    )
                    print(
                        "[StoredPlatformStore]: \(self.publishablePlatforms.count) Publishable stored platforms."
                    )
                    print(
                        "[StoredPlatformStore]: \(self.publishablePlatforms) Publishable stored platforms."
                    )
                    
                }
            } catch {
                print("[StoredPlatformStore]: Error loading stored platforms - \(error.localizedDescription)")
                // Update @Published error properties on the main thread.
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load stored platforms. \(error.localizedDescription)"
                    self.storedPlatforms = []
                    self.missingPlatforms = []
                    self.publishablePlatforms = []
                    self.isLoading = false // Loading finished (with error)
                }
                
            }
            
        }
    }
        
        
        func getStoredPlatform(byId id: String) -> StoredPlatform? {
            print("[StoredPlatformStore]: Getting stored platform for id \(id)...")
            var platform: StoredPlatform? = nil
            context.performAndWait {
                do {
                    platform = try handler.getStoredPlatform(byId: id)
                } catch {
                    print(
                        "[StoredPlatformStore]: Error getting stored platform synchronously - \(error.localizedDescription)"
                    )
                }
            }
            return platform
        }
        
        func putStoredPlatform(_ storedPlatform: StoredPlatform) {
            print(
                "[StoredPlatformStore]: Adding stored platform '\(storedPlatform.name)'..."
            )
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            context.perform {
                do {
                    try self.handler.putStoredPlatform(platformAccount: storedPlatform)
                    print("[StoredPlatformStore]: Platform '\(storedPlatform.name)' added successfully.")
                } catch {
                    print("[StoredPlatformStore]: Error putting stored platform \(storedPlatform.name) - \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to put stored platform '\(storedPlatform.name)'. \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
            
        }
        
        func deleteStoredPlatform(byId id: String) {
            print("[StoredPlatformStore]: Deleting stored platform by id \(id)...")
            
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            context.performAndWait {
                do {
                    try self.handler.deleteStoredPlatform(byId: id)
                    print("[StoredPlatformStore]: stored platform \(id) deleted successfully.")
                } catch {
                    print( "[StoredPlatformStore]: Error deleting stored platform '\(id)' - \(error.localizedDescription)")
                    self.errorMessage =
                    "Failed to delete stored platform '\(id)'. \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
        
        
        func deleteAllStoredPlatforms() {
            print("[StoredPlatformStore]: Deleting all stored platforms...")
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            context.performAndWait {
                do {
                    try self.handler.deleteAllStoredPlatformAccounts()
                    print(
                        "[StoredPlatformStore]: All stored platforms deleted successfully."
                    )
                }catch {
                    print(
                        "[StoredPlatformStore]: Error deleting all stored platforms - \(error.localizedDescription)"
                    )
                    DispatchQueue.main.async {
                        self.errorMessage =
                        "Failed to delete all stored platforms. \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
        
        func refresh() {
            print("[StoredPlatformStore]: Manual refresh requested...")
            getStoredPlatforms()
        }
    }
