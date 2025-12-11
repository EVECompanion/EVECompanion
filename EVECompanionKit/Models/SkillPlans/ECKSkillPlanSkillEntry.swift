//
//  ECKSkillPlanSkillEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.12.25.
//

import Foundation

public struct ECKSkillPlanSkillEntry: Codable, Hashable {
    
    public let skill: ECKItem
    public let level: Int
    
    public var skillTime: TimeInterval?
    
}

extension Collection where Element == ECKSkillPlanSkillEntry {
    var totalTrainingTime: TimeInterval {
        return self.reduce(0, { partialResult, entry in
            guard let skillTime = entry.skillTime else {
                logger.error("Entry \(entry) has no skillTime set.")
                return partialResult
            }
            
            return partialResult + skillTime
        })
    }
}
