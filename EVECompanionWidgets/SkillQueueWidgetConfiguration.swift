//
//  SkillQueueWidgetConfiguration.swift
//  EVECompanionWidgets
//
//  Created by Jonas Schlabertz on 21.10.25.
//

import WidgetKit
import AppIntents

struct SkillQueueWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
//    @Parameter(title: "Character")
    var character: WidgetCharacter = .dummy
}
