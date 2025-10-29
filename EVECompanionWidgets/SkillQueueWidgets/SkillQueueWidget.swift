//
//  SkillQueueWidget.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation
import WidgetKit
import SwiftUI

struct SkillQueueWidget: Widget {
    let kind: String = "SkillQueueWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: SkillQueueWidgetConfiguration.self,
                               provider: SkillQueueWidgetTimelineProvider()) { entry in
            SkillQueueEntryView(entry: entry)
                .containerBackground(.background,
                                     for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    SkillQueueWidget()
} timeline: {
    SkillQueueWidgetTimelineEntry.dummy1
    SkillQueueWidgetTimelineEntry.dummy2
    SkillQueueWidgetTimelineEntry.dummy3
}
