//
//  SkillQueueWidgetTimelineEntry.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation
import WidgetKit

struct SkillQueueWidgetTimelineEntry: TimelineEntry {
    
    let date: Date
    
    let character: WidgetCharacter
    let skillQueue: [SkillQueueEntry]
    
    static var dummy1: SkillQueueWidgetTimelineEntry = {
        let dummy1Skill = SkillQueueEntry.dummy1
        return .init(date: dummy1Skill.startDate!,
                     character: .dummy,
                     skillQueue: [dummy1Skill, .dummy2])
    }()
    
    static var dummy2: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.startDate!,
                     character: .dummy,
                     skillQueue: [.dummy2])
    }()
    
    static var dummy3: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.finishDate!,
                     character: .dummy,
                     skillQueue: [])
    }()
}
