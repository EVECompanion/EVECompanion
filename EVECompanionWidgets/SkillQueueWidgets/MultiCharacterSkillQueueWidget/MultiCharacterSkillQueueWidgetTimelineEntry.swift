//
//  MultiCharacterSkillQueueWidgetTimelineEntry.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import WidgetKit

struct MultiCharacterSkillQueueWidgetTimelineEntry: TimelineEntry {
    
    let date: Date
    let entries: [SkillQueueWidgetTimelineEntry]
    
    static var dummy1: MultiCharacterSkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueWidgetTimelineEntry.dummy3.date, entries: [.dummy3, .dummy4])
    }()
    
    static var dummy2: MultiCharacterSkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueWidgetTimelineEntry.dummy4.date, entries: [.dummy3, .dummy4])
    }()
    
}
