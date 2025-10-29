//
//  SkillQueueEntry.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation

struct SkillQueueEntry: Identifiable {
    
    var id: String {
        return skillName
    }
    
    let skillName: String
    let startDate: Date?
    let finishDate: Date?
    
    static var dummy1: SkillQueueEntry = {
        return .init(skillName: "Amarr Titan IV",
                     startDate: Date() - 3600,
                     finishDate: Date() + 5)
    }()
    
    static var dummy2: SkillQueueEntry = {
        return .init(skillName: "Amarr Titan V",
                     startDate: dummy1.finishDate,
                     finishDate: dummy1.finishDate! + 5)
    }()
}
