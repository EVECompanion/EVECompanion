//
//  NumberFormatters.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 09.05.24.
//

import Foundation

struct ECFormatters {
    
    static func iskShort(_ isk: Double) -> String {
        let formatter = NumberFormatter()
        
        if Int(isk / 1_000_000_000_000) > 0 {
            formatter.maximumFractionDigits = 3
            return "\(formatter.string(for: isk / 1_000_000_000_000) ?? "")T"
        } else if Int(isk / 1_000_000_000) > 0 {
            formatter.maximumFractionDigits = 3
            return "\(formatter.string(for: isk / 1_000_000_000) ?? "")B"
        } else if Int(isk / 1_000_000) > 0 {
            formatter.maximumFractionDigits = 1
            return "\(formatter.string(for: isk / 1_000_000) ?? "")M"
        } else if Int(isk / 1_000) > 0 {
            return "\(formatter.string(for: Int(isk / 1_000)) ?? "")k"
        } else {
            return formatter.string(for: isk) ?? isk.description
        }
    }
    
    static func iskLong(_ isk: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(for: isk) ?? isk.description
    }
    
    static func securityStatus(_ securityStatus: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(for: securityStatus) ?? securityStatus.description
    }
    
    static func skillPointsShort(_ skillPoints: Int) -> String {
        let formatter = NumberFormatter()
        
        if Int(skillPoints / 1_000_000) > 0 {
            formatter.maximumFractionDigits = 1
            return "\(formatter.string(for: skillPoints / 1_000_000) ?? "")M"
        } else if Int(skillPoints / 1_000) > 0 {
            return "\(formatter.string(for: Int(skillPoints / 1_000)) ?? "")k"
        } else {
            return formatter.string(for: skillPoints) ?? skillPoints.description
        }
    }
    
    static func skillPointsLong(_ skillPoints: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(for: skillPoints) ?? skillPoints.description
    }
    
    static func skillLevel(level: Int, showUntrainedString: Bool = false) -> String {
        switch level {
        case 0:
            return showUntrainedString ? "Untrained" : ""
        case 1:
            return "I"
        case 2:
            return "II"
        case 3:
            return "III"
        case 4:
            return "IV"
        case 5:
            return "V"
        default:
            return ""
        }
    }
    
    static func remainingTime(remainingTime: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: remainingTime) ?? ""
    }
    
    static func timeInterval(timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated

        return formatter.string(from: timeInterval) ?? ""
    }
    
    static func dateFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if UserDefaults.standard.showDatesInUTC,
           let utcTimezone = TimeZone(identifier: "UTC") {
            formatter.timeZone = utcTimezone
        }

        return formatter.string(from: date)
    }
    
    static func jumpRange(_ range: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter.string(for: range) ?? range.description
    }
    
    static func jumpDistance(_ range: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.numberStyle = .decimal
        return formatter.string(for: range) ?? range.description
    }
    
    static func fuelConsumption(_ consumption: Int) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter.string(for: consumption) ?? consumption.description
    }
    
    static func sdeSize(_ size: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(for: size) ?? "unknown"
    }
    
    static func attributeValue(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = " "
        return formatter.string(for: value) ?? value.description
    }
    
}
