//
//  SkillQueueWidgetConfiguration.swift
//  EVECompanionWidgets
//
//  Created by Jonas Schlabertz on 21.10.25.
//

import WidgetKit
import AppIntents
import EVECompanionKit

struct SkillQueueWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Character" }
    static var description: IntentDescription { "Selects the character to display the skill queue for." }
    
    // An example configurable parameter.
    @Parameter(title: "Character", default: .dummy)
    var character: WidgetCharacter
    
    init(character: WidgetCharacter) {
        self.character = character
    }
    
    init() {
        
    }
}
