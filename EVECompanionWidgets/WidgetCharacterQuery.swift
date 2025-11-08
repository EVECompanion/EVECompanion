//
//  WidgetCharacterQuery.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation
import AppIntents
import EVECompanionKit

struct WidgetCharacterQuery: EntityQuery {
    
    typealias Entity = WidgetCharacter
    
    func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        var result: [Entity] = []
        
        for identifier in identifiers {
            if identifier == WidgetCharacter.dummy1.id {
                result.append(.dummy1)
                continue
            }
            
            guard let data = await ECKWidgetDataStorage.shared.loadSkillQueue(for: identifier) else {
                continue
            }
            
            result.append(.init(data: data))
        }
        
        if result.isEmpty {
            result.append(.dummy1)
        }
        
        return result
    }
    
    func suggestedEntities() async throws -> [Entity] {
        let skillQueues = await ECKWidgetDataStorage.shared.loadAllSkillQueues()
        var result: [Entity] = skillQueues.map({ .init(data: $0) })
        if result.isEmpty {
            result.append(.dummy1)
        }
        return result
    }
    
}
