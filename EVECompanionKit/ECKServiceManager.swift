//
//  ECKServiceManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 18.03.26.
//

import Foundation
public import Combine

public class ECKServiceManager: ObservableObject {
    
    private var skillPlanManagers: [Int: ECKSkillPlanManager] = [:]
    
    public init() { }
    
    
    public func skillPlanManager(character: ECKCharacter) -> ECKSkillPlanManager {
        guard let skillPlanManager = skillPlanManagers[character.id] else {
            let manager = ECKSkillPlanManager(character: character)
            skillPlanManagers[character.id] = manager
            return manager
        }
        
        return skillPlanManager
    }
    
}
