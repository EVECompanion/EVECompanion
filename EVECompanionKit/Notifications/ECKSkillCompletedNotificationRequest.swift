//
//  ECKSkillCompletedNotificationRequest.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 05.05.25.
//

import Foundation
import UserNotifications

struct ECKSkillCompletedNotificationRequest: ECKNotificationRequest {
    
    private var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Skill Training Complete"
        content.body = "\(character.name): \(skill.skill.name) \(ECFormatters.skillLevel(level: skill.finishLevel))"
        content.userInfo["character"] = character.id
        content.threadIdentifier = character.id.description
        return content
    }
    
    private var trigger: UNNotificationTrigger? {
        guard let triggerDate = skill.finishDate else {
            return nil
        }
        
        guard triggerDate > Date() else {
            return nil
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        return UNCalendarNotificationTrigger(dateMatching: components,
                                             repeats: false)
    }
    
    var request: UNNotificationRequest? {
        guard let trigger else {
            return nil
        }
        
        return .init(identifier: UUID().uuidString,
                     content: content,
                     trigger: trigger)
    }
    
    private let character: ECKCharacter
    private let skill: ECKCharacterSkillQueueEntry
    
    init(character: ECKCharacter, skill: ECKCharacterSkillQueueEntry) {
        self.character = character
        self.skill = skill
    }
    
}
