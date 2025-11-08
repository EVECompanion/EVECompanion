//
//  WidgetCharacter.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation
import EVECompanionKit
import AppIntents

struct WidgetCharacter: AppEntity {
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Character"
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
    static var defaultQuery = WidgetCharacterQuery()
    
    let name: String
    let id: Int
    
    init(character: ECKCharacter) {
        self.name = character.name
        self.id = character.id
    }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    init(data: ECKWidgetDataStorage.SkillQueueData) {
        self.id = data.characterId
        self.name = data.characterName
    }
    
    static var dummy1: WidgetCharacter {
        return .init(id: -1, name: "Demo Character")
    }
    
    static var dummy2: WidgetCharacter {
        return .init(id: -2, name: "Demo Character")
    }
    
    static var dummy3: WidgetCharacter {
        return .init(id: -3, name: "Demo Character 2")
    }
}
