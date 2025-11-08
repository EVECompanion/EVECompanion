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
                     character: .dummy1,
                     skillQueue: [dummy1Skill, .dummy2])
    }()
    
    static var dummy2: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.startDate!,
                     character: .dummy1,
                     skillQueue: [.dummy2])
    }()
    
    static var dummy3: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.finishDate!,
                     character: .dummy1,
                     skillQueue: [])
    }()
    
    static var dummy4: SkillQueueWidgetTimelineEntry = {
        let dummy1Skill = SkillQueueEntry.dummy1
        return .init(date: SkillQueueEntry.dummy2.finishDate!,
                     character: .dummy2,
                     skillQueue: [dummy1Skill, .dummy2])
    }()
}
