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
        case .skill(let entry):
            return entry.level
        }
    }
    
    var skill: ECKSkillPlanSkillEntry? {
        switch self {
        case .remap(let eCKSkillPlanRemap):
            return nil
        case .skill(let entry):
            return entry
        }
    }
    
    var isRemapPoint: Bool {
        switch self {
        case .remap:
            return true
        case .skill:
            return false
        }
    }
    
    var isSkillEntry: Bool {
        switch self {
        case .remap:
            return false
        case .skill:
            return true
        }
    }
    
    case remap(ECKSkillPlanRemap?)
    case skill(ECKSkillPlanSkillEntry)
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .remap(let remap):
            hasher.combine(remap)
        case .skill(let entry):
            hasher.combine(entry)
        }
    }
    
}
