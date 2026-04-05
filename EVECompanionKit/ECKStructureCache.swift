//
//  ECKStructureCache.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.25.
//

import Foundation
import Combine

actor ECKStructureCache {
    
    typealias Structure = ECKStructureResource.StructureResponse
    
    private struct CacheEntry {
        var structure: Structure?
        var unavailableTokenIds: Set<String> = []
    }
    
    private struct TaskKey: Hashable {
        let structureId: Int
        let tokenId: String
    }
    
    static let shared = ECKStructureCache()
    private var cachedResults: [Int: CacheEntry] = [:]
    private var structureTasks: [TaskKey: Task<Structure?, Never>] = [:]
    
    private init() {}
    
    func get(structureId: Int, using token: ECKToken) async -> Structure? {
        let tokenId = token.id
        let taskKey = TaskKey(structureId: structureId, tokenId: tokenId)
        
        if let cachedEntry = cachedResults[structureId] {
            if let structure = cachedEntry.structure {
                return structure
            }
            
            if cachedEntry.unavailableTokenIds.contains(tokenId) {
                return nil
            }
        }
        
        if let structureTask = structureTasks[taskKey] {
            return await structureTask.value
        }
        
        let task: Task<Structure?, Never> = Task {
            defer {
                structureTasks[taskKey] = nil
            }
            
            do {
                let resource = ECKStructureResource(
                    structureId: structureId,
                    token: token
                )
                let response = try await ECKWebService().loadResource(resource: resource)
                let structure = response.response
                cachedResults[structureId] = CacheEntry(structure: structure)
                logger.debug("Loaded structure \(String(describing: structure.name))")
                return structure
            } catch {
                var cachedEntry = cachedResults[structureId] ?? CacheEntry(structure: nil)
                cachedEntry.unavailableTokenIds.insert(tokenId)
                cachedResults[structureId] = cachedEntry
                logger.error("Cannot load structure data for \(structureId): \(error)")
                return nil
            }
        }
        
        structureTasks[taskKey] = task
        
        return await task.value
    }
    
}
