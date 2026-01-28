//
//  ECKSkillPlanSkillEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.12.25.
//

import Foundation

public struct ECKSkillPlanSkillEntry: Codable, Hashable {
    
    enum CodingKeys: CodingKey {
        case skill
        case level
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.skill = try container.decode(ECKItem.self, forKey: .skill)
        self.level = try container.decode(Int.self, forKey: .level)
    }
    
    init(skill: ECKItem, level: Int, skillTime: TimeInterval? = nil, earliestFinishDate: Date? = nil) {
        self.skill = skill
        self.level = level
        self.skillTime = skillTime
        self.earliestFinishDate = earliestFinishDate
    }
    
    public let skill: ECKItem
    public let level: Int
    
    public var skillTime: TimeInterval?
    public var earliestFinishDate: Date?
    
    public static let dummy: ECKSkillPlanSkillEntry = {
        var result = ECKSkillPlanSkillEntry(skill: .amarrTitan, level: 4)
        result.skillTime = .fromHours(hours: 2) + .fromDays(days: 1)
        result.earliestFinishDate = Date().addingTimeInterval(result.skillTime ?? 0)
        return result
    }()
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.skill, forKey: .skill)
        try container.encode(self.level, forKey: .level)
    }
    
}

extension Collection where Element == ECKSkillPlanSkillEntry {
    var totalTrainingTime: TimeInterval {
        return self.reduce(0, { partialResult, entry in
            guard let skillTime = entry.skillTime else {
                logger.error("Entry \(entry) has no skillTime set.")
                return partialResult
            }
            
            return partialResult + skillTime
        })
    }
}
