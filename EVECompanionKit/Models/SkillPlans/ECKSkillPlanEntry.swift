//
//  ECKSkillPlanEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation

public enum ECKSkillPlanEntry: Codable, Identifiable, Hashable {
    
    public var id: Int {
        return self.hashValue
    }
    
    var level: Int? {
        switch self {
        case .remap:
            return nil
        case .skill(_, let level):
            return level
        }
    }
    
    case remap(ECKSkillPlanRemap?)
    case skill(skill: ECKItem, level: Int)
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .remap(let remap):
            hasher.combine(remap)
        case .skill(let skill, let level):
            hasher.combine(skill)
            hasher.combine(level)
        }
    }
    
}
