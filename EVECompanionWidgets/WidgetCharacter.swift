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
    
    static var dummy: WidgetCharacter {
        return .init(id: 2123087197, name: "Demo Character")
    }
}
