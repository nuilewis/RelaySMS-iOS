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

// MARK: - Platforms Model
// Service to handler platforms
struct Platform: Identifiable {
    let name: String
    let protocolType: Publisher.ProtocolTypes
    let serviceType: Publisher.ServiceTypes
    let shortcode: String
    let supportUrlScheme: Bool
    let imageData: Data?

    var id: String { name }

    init(
        name: String, protocolType: Publisher.ProtocolTypes, serviceType: Publisher.ServiceTypes,
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
        protocolType: Publisher.ProtocolTypes? = nil,
        serviceType: Publisher.ServiceTypes? = nil,
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
            protocolType: Publisher.ProtocolTypes(rawValue: entity.protocol_type ?? "oauth2") ?? Publisher.ProtocolTypes.OAUTH2,
            serviceType: Publisher.ServiceTypes(rawValue: entity.service_type ?? "text") ?? Publisher.ServiceTypes.TEXT,
            shortcode: entity.shortcode ?? "",
            supportUrlScheme: entity.support_url_scheme,
            imageData: entity.image
        )
    }

}

// MARK: - PlatformsEntityHandler

// Service to handler platforms
struct PlatformsEntityHandler {
    let context: NSManagedObjectContext
    func putPlatform(_ platform: Platform) throws {

        // Make sure platform name is not empty, as that will be used as the identitier
        guard !platform.name.isEmpty else {
            print("[PlatformsEntityHandler]:Error: Platform name cannot be empty for put operation")
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
                print("[PlatformsEntityHandler]: Updating existing platform with name: \(platform.name)")
                entityToSave = existing
            } else {
                print("[PlatformsEntityHandler]: Creating new platform with name: \(platform.name)")
                entityToSave = PlatformsEntity(context: context)
                entityToSave.name = platform.name
            }

            entityToSave.name = platform.name
            entityToSave.protocol_type = platform.protocolType.rawValue
            entityToSave.service_type = platform.serviceType.rawValue
            entityToSave.shortcode = platform.shortcode
            entityToSave.support_url_scheme = platform.supportUrlScheme
            entityToSave.image = platform.imageData

            try context.save()
            print("[PlatformsEntityHandler]: Successfully saved platform: \(platform.name)")

        } catch {
            print("[PlatformsEntityHandler]: Error saving platform (name: \(platform.name)): \(error)")
            throw error
        }
    }
    func getAllPlatforms() throws -> [Platform] {
       // print("[PlatformsEntityHandler]: Getting all platforms")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
            as NSFetchRequest<PlatformsEntity>

        do {
            let entities = try context.fetch(fetchRequest)
            if entities.isEmpty {
                print("[PlatformsEntityHandler]: No platforms found")
            } else {
               // print("[PlatformsEntityHandler]: Successfully fetched \(entities.count) platforms")
            }

            return entities.compactMap { entity in
                try? Platform.fromEntity(entity)
            }
        } catch {
            print("[PlatformsEntityHandler]: Failed to fetch platforms: \(error)")
            throw error
        }
    }

    func getPlatform(byName platformName: String) throws -> Platform? {

        guard !platformName.isEmpty else {
            print("[PlatformsEntityHandler]: Error: Platform name cannot be empty for fetch operation.")
            return nil
        }

       // print("[PlatformsEntityHandler]: Getting stored platform with name \(platformName)")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", platformName)

        do {
            guard let entity = try context.fetch(fetchRequest).first else {
                print("[PlatformsEntityHandler]: No platform found with name: \(platformName)")
                return nil
            }

            return try Platform.fromEntity(entity)

        } catch {
            print(
                "[PlatformsEntityHandler]: Failed to fetch platform with name \(platformName): \(error)")
            throw error
        }
    }

    func deleteStoredPlatform(byName platformName: String) throws {
        guard !platformName.isEmpty else {
            print("[PlatformsEntityHandler]: Error: Platform name cannot be empty for delete operation.")
            return
        }

       // print("[PlatformsEntityHandler]: Deleting platform with name : \(platformName)")
        let fetchRequest: NSFetchRequest<PlatformsEntity> =
            PlatformsEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", platformName)

        do {
            guard let entityToDelete = try context.fetch(fetchRequest).first
            else {
                print(
                    "[PlatformsEntityHandler]: Platform with name '\(platformName)' not found. Unable to delete."
                )
                return
            }

            context.delete(entityToDelete)
            try context.save()
            print("[PlatformsEntityHandler]: Successfully deleted platform with name: \(platformName)")
        } catch {
            print("[PlatformsEntityHandler]: Error deleting platform with name \(platformName): \(error)")
            throw error
        }
    }

    func deleteAllPlatforms() throws {
        print("[PlatformsEntityHandler]: Deleting all platforms...")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            PlatformsEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(
            fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            try context.execute(batchDeleteRequest)
            print("[PlatformsEntityHandler]: Successfully deleted all platforms via batch delete.")
        } catch {
            print("[PlatformsEntityHandler]: Error deleting all platforms: \(error)")
            context.rollback()
            throw error
        }
    }
}

// MARK: - Platform Store
// This acts as out state management class
class PlatformStore: ObservableObject {
    @Published var platforms: [Platform] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let handler: PlatformsEntityHandler
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        self.handler = PlatformsEntityHandler(context: context)
        
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.getPlatforms()
        }
        getPlatforms()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func getPlatforms() {
        print("[PlatformStore]: Getting platforms...")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        context.performAndWait {
            do {
                let fetchedPlatforms = try self.handler.getAllPlatforms()
                
                DispatchQueue.main.async {
                    self.platforms = fetchedPlatforms
                    self.isLoading = false
                    print("[PlatformStore]: Loaded \(self.platforms.count) platforms.")
                }
            }catch {
                print("[PlatformStore]: Error loading platforms - \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load platforms. \(error.localizedDescription)"
                    self.platforms = []
                    self.isLoading = false
                }

            }
        }
        
    }

    func getPlatform(byName name: String) -> Platform? {
        print("[PlatformStore]: Getting platform for name \(name)...")
        var platform: Platform? = nil

        context.performAndWait {
            do {
                platform = try handler.getPlatform(byName: name)
            } catch {
                print("[PlatformStore]: Error getting platform synchronously - \(error.localizedDescription)")
            }
    
        }
        return platform
    
    }

    func putPlatform(_ platform: Platform) {
        print("[PlatformStore]: Adding platform '\(platform.name)'...")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        context.perform {
            do {
                try self.handler.putPlatform(platform)
                print("[PlatformStore]: Platform '\(platform.name)' added successfully.")
            } catch {
                DispatchQueue.main.async {
                    print("[PlatformStore]: Error putting platform \(platform.name) - \(error.localizedDescription)")
                    self.errorMessage = "Failed to put platform '\(platform.name)'. \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func savePlatform(_ platform: Platform) {
         do {
             try self.handler.putPlatform(platform)
             print("[PlatformStore]: Platform '\(platform.name)' added successfully.")
             // getPlatforms will be called automatically via the NotificationCenter observer
         } catch {
             print("[PlatformStore]: Error putting platform \(platform.name) - \(error.localizedDescription)")
             self.errorMessage = "Failed to put platform '\(platform.name)'. \(error.localizedDescription)"
             self.isLoading = false
         }
     }

    func deletePlatform(byName platformName: String) {
        print("[PlatformStore]: Deleting platform \(platformName)...")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        context.performAndWait {
            do {
                try self.handler.deleteStoredPlatform(byName: platformName)
                print("[PlatformStore]: platform \(platformName) deleted successfully.")
            }catch {
                DispatchQueue.main.async {
                    print("[PlatformStore]: Error deleting platform '\(platformName)' - \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete platform '\(platformName)'. \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
        
    }

    func deleteAllPlatforms() {
        print("[PlatformStore]: Deleting all platforms...")
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        context.performAndWait {
            do {
                try self.handler.deleteAllPlatforms()
                print("[PlatformStore]: All platforms deleted successfully.")
            }catch {
                DispatchQueue.main.async {
                    print("[PlatformStore]: Error deleting all platforms - \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete all platforms. \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }

    }
    
    
    // Add a manual refresh method for when you want to force a refresh
      func refresh() {
          print("[PlatformStore]: Manual refresh requested...")
          getPlatforms()
      }
}
