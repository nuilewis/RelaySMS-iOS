//
//  StoredTokensEntityManager.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 24/04/2025.
//

import CoreData

struct StoredTokensEntityManager {
    let context: NSManagedObjectContext
    
    // C R U D   O P S
    func getAllStoredTokens() -> [StoredToken] {
        print("Getting all stored tokens")
        let fetchRequest: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest() as NSFetchRequest<StoredTokenEntity>
        do {
            let tokensEntities: [StoredTokenEntity] = try context.fetch(fetchRequest)
            
            if tokensEntities.isEmpty {
                print("No tokens found")
            } else {
                print("Successfully fetched tokens")
            }
            
            var storedTokens: [StoredToken] = []
            
            for  tokenEntity in tokensEntities {
                storedTokens.append(try StoredToken.fromEntity(tokenEntity))
            }
        
            return storedTokens
        } catch {
            print("Failed to fetch stored tokens: \(error)")
            return []
        }
    }
    
    
    func getStoredToken(forPlatform platformId: String) -> StoredToken? {
        print("Getting stored token with id \(platformId)")
        let request: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", platformId)
        do {
            let tokenEntity: StoredTokenEntity? = try context.fetch(request).first
            
            if let entity = tokenEntity {
                return try StoredToken.fromEntity(entity)
            } else {
                print("No token found for platform with id \(platformId)")
                return nil
            }
        } catch {
            print("Failed to fetch stored tokens: \(error)")
            return nil
        }
    }
    
    
    func putStoredToken(token: StoredToken) -> Void {
        let fetchRequest: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", token.id)
        
        do {
            if let existingToken = try context.fetch(fetchRequest).first {
                print("An existing token exist, updating it...")
                existingToken.accessToken = token.accessToken
                existingToken.refreshToken = token.refreshToken
                existingToken.idToken = token.idToken
            } else {
                print("Adding a new token...")
                let newStoredToken = StoredTokenEntity(context: context)
                newStoredToken.id = token.id
                newStoredToken.accessToken = token.accessToken
                newStoredToken.refreshToken = token.refreshToken
                newStoredToken.idToken = token.idToken
            }
            try context.save();
            print("Successfully saved token")
        } catch {
            print("An error occurred while trying to save the token: \(error)")
        }
    }
    
    
    func deleteAllStoredTokens() -> Void {
        print("Deleting all tokens....")
        let fetchRequest: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest()
        do {
            let tokenEntities: [StoredTokenEntity] = try context.fetch(fetchRequest)
            for entity in tokenEntities {
                context.delete(entity)
            }
            try context.save()
            print("Deleted all tokens successfully")
        } catch {
            print("Unable to delete all tokens: \(error)")
        }
    
    }
    
    func deleteStoredTokenById(forPlatform platformId: String) -> Void {
        print("Deleting token for platform: \(platformId)")
        let fetchRequest: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", platformId)
        
        do {
            let tokenEntity: StoredTokenEntity? = try context.fetch(fetchRequest).first
            
            if let entity: StoredTokenEntity = tokenEntity {
                 context.delete(entity)
                try context.save()
                print("Successfully deleted token")
            }else {
                print("Stored token for platform \(platformId) not found.. Unable to delete")
            }
        } catch {
            print("Unable to delete token: \(error)")
        }
    }
    
    func deleteStoredToken(token: StoredToken) -> Void {
        print("Deleting token for platform: \(token.id)")
        let fetchRequest: NSFetchRequest<StoredTokenEntity> = StoredTokenEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", token.id)
        
        do {
            let tokenEntity: StoredTokenEntity? = try context.fetch(fetchRequest).first
            
            if let entity: StoredTokenEntity = tokenEntity {
                 context.delete(entity)
                try context.save()
                print("Successfully deleted token")
            }else {
                print("Stored token for platform \(token.id) not found.. Unable to delete")
            }
        } catch {
            print("Unable to delete token: \(error)")
        }
        
    }
    
    
    // H E L P E R   M E T H O D S
    func storedTokenExists(forPlarform platformId: String) -> Bool {
        print("Checking if token for platform id exists: \(platformId)")
        let storedToken = getStoredToken(forPlatform: platformId)
        var tokenExists: Bool = false
        if let token = storedToken {
            tokenExists =  !token.accessToken.isEmpty  && !token.refreshToken.isEmpty
        }
        if tokenExists {
            print("Yes, token exists for platform id: \(platformId)")
        } else {
            print("No, token does not exist for platform with id: \(platformId)")
        }
        return tokenExists
    }
    
}



// Simple model to handle stored token entities
struct StoredToken: Identifiable {
    let id: String
    let accessToken: String
    let refreshToken: String
    let idToken: String?
    
    
    func toEntity(context: NSManagedObjectContext) -> StoredTokenEntity {
        let entity = StoredTokenEntity(context: context)
        entity.id = self.id
        entity.accessToken = self.accessToken
        entity.refreshToken = self.refreshToken
        entity.idToken = self.idToken
        return entity
    }
    
    func copyWith(accessToken: String?, refreshToken: String?, idToken: String?) -> StoredToken {
        return StoredToken(
            id: self.id,
            accessToken: accessToken ?? self.accessToken,
            refreshToken: refreshToken ?? self.refreshToken,
            idToken: idToken ?? self.idToken
        )
    }
    
    static func fromEntity(_ entity: StoredTokenEntity) throws -> StoredToken {
        if entity.id == nil {
            throw CustomError(message: "Invalid Entity: Entity ID is nil")
        } else if entity.id!.isEmpty  {
            throw CustomError(message: "Invalid Entity: Entity ID is empty")
        }
        
        return StoredToken(
            id: entity.id ?? "",
            accessToken: entity.accessToken ?? "",
            refreshToken: entity.refreshToken ?? "",
            idToken: entity.idToken ?? ""
        )
    }
    
}
