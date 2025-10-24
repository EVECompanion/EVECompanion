//
//  ECKWidgetDataProvider.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 23.10.25.
//

import Foundation

public class ECKWidgetDataProvider {
    
    static let shared: ECKWidgetDataProvider = .init()
    
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()
    
    init() {
        
    }
    
    // MARK: - Skill Queues
    
    func storeSkillQueue(for character: ECKCharacter, skillQueue: ECKCharacterSkillQueue) {
        
    }
    
    
    
    
}
