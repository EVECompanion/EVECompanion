//
//  ECKAllianceManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.03.25.
//

import Foundation

internal actor ECKAllianceManager {
    
    static let shared = ECKAllianceManager()
    private var alliances: [Int: ECKAlliance] = [:]
    private var allianceTasks: [Int: Task<ECKAlliance?, any Error>] = [:]
    
    private init() {}
    
    func get(allianceId: Int) async -> ECKAlliance? {
        if let alliance = alliances[allianceId] {
            return alliance
        }
        
        if let allianceTask = allianceTasks[allianceId] {
            return try? await allianceTask.value
        }
        
        let task: Task<ECKAlliance?, any Error> = Task {
            defer {
                allianceTasks[allianceId] = nil
            }
            
            do {
                let resource = ECKAllianceResource(allianceId: allianceId)
                let response = try await ECKWebService().loadResource(resource: resource)
                let alliance = response.response
                alliances[allianceId] = alliance
                logger.debug("Loaded alliance \(String(describing: alliance?.name))")
                return alliance
            } catch {
                logger.error("Cannot load alliance data for \(allianceId): \(error)")
                throw error
            }
        }
        
        allianceTasks[allianceId] = task
        
        return try? await task.value
    }
    
}
