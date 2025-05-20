//
//  ECKEmptySkillQueueNotificationRequest.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 03.05.25.
//

import Foundation
import UserNotifications

struct ECKEmptySkillQueueWarningNotificationRequest: ECKNotificationRequest {
    
    private var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Skill Queue Warning"
        content.body = "Skill queue for \(character.name) will finish in 24 hours!"
        content.userInfo["character"] = character.id
        return content
    }
    
    private var trigger: UNNotificationTrigger? {
        let triggerDate = skillQueueFinishDate - .fromHours(hours: 24)
        
        guard triggerDate > Date() else {
            return nil
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .minute, .second], from: triggerDate)
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
    private let skillQueueFinishDate: Date
    
    init(character: ECKCharacter, skillQueueFinishDate: Date) {
        self.character = character
        self.skillQueueFinishDate = skillQueueFinishDate
    }
    
}
