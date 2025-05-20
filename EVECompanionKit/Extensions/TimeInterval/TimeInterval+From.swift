//
//  TimeInterval+From.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

extension TimeInterval {
    
    static func fromSeconds(seconds: Double) -> TimeInterval {
        return seconds
    }
    
    static func fromMinutes(minutes: Double) -> TimeInterval {
        return minutes * 60
    }
    
    static func fromHours(hours: Double) -> TimeInterval {
        return 60 * fromMinutes(minutes: hours)
    }
    
    static func fromDays(days: Double) -> TimeInterval {
        return 24 * fromHours(hours: days)
    }
    
}
