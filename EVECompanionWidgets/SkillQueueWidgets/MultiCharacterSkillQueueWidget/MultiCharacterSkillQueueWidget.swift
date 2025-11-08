//
//  MultiCharacterSkillQueueWidget.swift
//  EVECompanionWidgets
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import WidgetKit
import SwiftUI

struct MultiCharacterSkillQueueWidget: Widget {
    let kind: String = "MultiCharacterSkillQueueWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: MultiCharacterSkillQueueWidgetConfiguration.self,
                               provider: MultiCharacterSkillQueueWidgetTimelineProvider()) { entry in
            MultiCharacterSkillQueueEntryView(entry: entry)
                .containerBackground(.background,
                                     for: .widget)
        }
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemMedium) {
    MultiCharacterSkillQueueWidget()
} timeline: {
    MultiCharacterSkillQueueWidgetTimelineEntry.dummy1
}
