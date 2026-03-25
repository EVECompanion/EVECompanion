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
    
    static let shared = ECKStructureCache()
    private var structures: [Int: Structure] = [:]
    private var structureTasks: [Int: Task<Structure?, any Error>] = [:]
    
    private init() {}
    
    func get(structureId: Int, using token: ECKToken) async -> Structure? {
        if let alliance = structures[structureId] {
            return alliance
        }
        
        if let allianceTask = structureTasks[structureId] {
            return try? await allianceTask.value
        }
        
        let task: Task<Structure?, any Error> = Task {
            defer {
                structureTasks[structureId] = nil
            }
            
            do {
                let resource = ECKStructureResource(
                    structureId: structureId,
                    token: token
                )
                let response = try await ECKWebService().loadResource(resource: resource)
                let structure = response.response
                structures[structureId] = structure
                logger.debug("Loaded structure \(String(describing: structure.name))")
                return structure
            } catch {
                logger.error("Cannot load structure data for \(structureId): \(error)")
                throw error
            }
        }
        
        structureTasks[structureId] = task
        
        return try? await task.value
    }
    
}
