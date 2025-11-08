//
//  MultiCharacterSkillQueueWidgetConfiguration.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import AppIntents
import EVECompanionKit

struct MultiCharacterSkillQueueWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Characters" }
    static var description: IntentDescription { "Selects the characters to display the skill queues for." }
    
    @Parameter(title: "Characters", default: [.dummy1], size: [
        .systemLarge: 4
    ])
    var characters: [WidgetCharacter]
    
    init(characters: [WidgetCharacter]) {
        self.characters = characters
    }
    
    init() {
        
    }
}
