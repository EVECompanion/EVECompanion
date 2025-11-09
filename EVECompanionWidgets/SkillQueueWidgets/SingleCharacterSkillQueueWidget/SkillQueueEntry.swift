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
                     finishDate: Date() + 3600)
    }()
    
    static var dummy2: SkillQueueEntry = {
        return .init(skillName: "Amarr Titan V",
                     startDate: dummy1.finishDate,
                     finishDate: dummy1.finishDate! + 3600 * 50)
    }()
    
    static var dummy3: SkillQueueEntry = {
        return .init(skillName: "Spaceship Command IV",
                     startDate: Date() - 3600,
                     finishDate: Date() + 10)
    }()
    
    static var dummy4: SkillQueueEntry = {
        return .init(skillName: "Spaceship Command V",
                     startDate: dummy3.finishDate,
                     finishDate: dummy3.finishDate! + 3600 * 50)
    }()
}
