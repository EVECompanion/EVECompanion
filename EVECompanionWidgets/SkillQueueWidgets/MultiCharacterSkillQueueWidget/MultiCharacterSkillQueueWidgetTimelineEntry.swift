//
//  MultiCharacterSkillQueueWidgetTimelineEntry.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import WidgetKit

struct MultiCharacterSkillQueueWidgetTimelineEntry: TimelineEntry {
    
    var date: Date {
        return entries.map({ $0.date }).min() ?? Date()
    }
    
    let entries: [SkillQueueWidgetTimelineEntry]
    
    static var dummy1: MultiCharacterSkillQueueWidgetTimelineEntry = {
        let dummy1Skill = SkillQueueEntry.dummy1
        let entry1 = SkillQueueWidgetTimelineEntry(date: dummy1Skill.startDate!,
                                                   character: .dummy1,
                                                   skillQueue: [dummy1Skill, .dummy2])
        let entry2 = SkillQueueWidgetTimelineEntry(date: dummy1Skill.startDate!,
                                                   character: .dummy2,
                                                   skillQueue: [dummy1Skill, .dummy2])
        return .init(entries: [entry1, entry2])
    }()
    
    static var dummy2: MultiCharacterSkillQueueWidgetTimelineEntry = {
        let dummy1Skill = SkillQueueEntry.dummy1
        let entry1 = SkillQueueWidgetTimelineEntry(date: dummy1Skill.startDate!,
                                                   character: .dummy2,
                                                   skillQueue: [dummy1Skill, .dummy2])
        let entry2 = SkillQueueWidgetTimelineEntry(date: dummy1Skill.startDate!,
                                                   character: .dummy3,
                                                   skillQueue: [dummy1Skill, .dummy2])
        return .init(entries: [entry1, entry2])
    }()
    
}
