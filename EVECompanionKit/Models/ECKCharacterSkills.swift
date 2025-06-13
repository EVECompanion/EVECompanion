//
//  ECKCharacterSkills.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 09.05.24.
//

import Foundation

public class ECKCharacterSkills: Decodable, Equatable, Hashable {
    
    private enum CodingKeys: String, CodingKey {
        case skillLevels = "skills"
        case totalSP = "total_sp"
        case unallocatedSP = "unallocated_sp"
    }
    
    public var skillLevels: [ECKCharacterSkillLevel]
    public var totalSP: Int
    public var unallocatedSP: Int?
    
    static let dummy: ECKCharacterSkills = .init()
    
    public static let empty: ECKCharacterSkills = {
        let res = ECKCharacterSkills()
        res.skillLevels = []
        res.totalSP = 0
        res.unallocatedSP = nil
        return res
    }()
    
    // Key: SkillId, Value: SkillLevel
    internal lazy var skillSet: [Int: Int] = {
        var result: [Int: Int] = [:]
        skillLevels.forEach { skillLevel in
            result[skillLevel.skill.skillId] = skillLevel.trainedSkillLevel
        }
        return result
    }()
    
    private init() {
        self.skillLevels = [.dummy1, .dummy2]
        self.totalSP = 15672976
        self.unallocatedSP = 1679235
    }
    
    public static func == (lhs: ECKCharacterSkills, rhs: ECKCharacterSkills) -> Bool {
        return lhs.skillLevels == rhs.skillLevels
            && lhs.totalSP == rhs.totalSP
            && lhs.unallocatedSP == rhs.unallocatedSP
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(skillLevels)
        hasher.combine(totalSP)
        hasher.combine(unallocatedSP)
    }
    
    public func isTrained(skillId: Int, level: Int) -> Bool {
        return (skillSet[skillId] ?? -1) >= level
    }
    
    internal func updateWithSkillQueue(_ queue: ECKCharacterSkillQueue) {
        for skillLevel in skillLevels {
            let finishedEntries = queue.finishedEntries.filter({ $0.skill == skillLevel.skill })
            if let maxFinishedEntry = finishedEntries.max(by: { $0.finishLevel < $1.finishLevel }) {
                skillLevel.trainedSkillLevel = maxFinishedEntry.finishLevel
            }
        }
    }
    
}

public class ECKCharacterSkillLevel: Decodable, Identifiable, Equatable, Hashable {
    
    private enum CodingKeys: String, CodingKey {
        case activeSkillLevel = "active_skill_level"
        case skill = "skill_id"
        case skillPointsInSkill = "skillpoints_in_skill"
        case trainedSkillLevel = "trained_skill_level"
    }
    
    public var id: Int {
        return skill.skillId
    }
    
    public let activeSkillLevel: Int
    public let skill: ECKCharacterSkill
    public let skillPointsInSkill: Int
    public var trainedSkillLevel: Int
    
    public static let dummy1: ECKCharacterSkillLevel = .init(activeSkillLevel: 5,
                                                             skill: .dummy1,
                                                             skillPointsInSkill: 1500000,
                                                             trainedSkillLevel: 5)
    
    public static let dummy2: ECKCharacterSkillLevel = .init(activeSkillLevel: 3,
                                                             skill: .dummy2,
                                                             skillPointsInSkill: 3400000,
                                                             trainedSkillLevel: 3)
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.activeSkillLevel = try container.decode(Int.self, forKey: .activeSkillLevel)
        self.skill = try container.decode(ECKCharacterSkill.self, forKey: .skill)
        self.skillPointsInSkill = try container.decode(Int.self, forKey: .skillPointsInSkill)
        self.trainedSkillLevel = try container.decode(Int.self, forKey: .trainedSkillLevel)
    }
    
    internal init(activeSkillLevel: Int, 
                  skill: ECKCharacterSkill,
                  skillPointsInSkill: Int,
                  trainedSkillLevel: Int) {
        self.activeSkillLevel = activeSkillLevel
        self.skill = skill
        self.skillPointsInSkill = skillPointsInSkill
        self.trainedSkillLevel = trainedSkillLevel
    }
    
    public static func == (lhs: ECKCharacterSkillLevel, rhs: ECKCharacterSkillLevel) -> Bool {
        return lhs.activeSkillLevel == rhs.activeSkillLevel
            && lhs.skill == rhs.skill
            && lhs.skillPointsInSkill == rhs.skillPointsInSkill
            && lhs.trainedSkillLevel == rhs.trainedSkillLevel
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(activeSkillLevel)
        hasher.combine(skill)
        hasher.combine(skillPointsInSkill)
        hasher.combine(trainedSkillLevel)
    }
    
}

public class ECKCharacterSkillQueue: Decodable, Equatable, Hashable {
    
    public let loadedEntries: [ECKCharacterSkillQueueEntry]
    public var currentEntries: [ECKCharacterSkillQueueEntry] {
        return loadedEntries.filter({
            guard let finishDate = $0.finishDate else {
                return true
            }
            
            return finishDate > Date()
        })
    }
    
    public var finishedEntries: [ECKCharacterSkillQueueEntry] {
        return loadedEntries.filter({
            guard let finishDate = $0.finishDate else {
                return true
            }
            
            return finishDate < Date()
        })
    }
    
    public static let dummy: ECKCharacterSkillQueue = .init()
    
    public var first: ECKCharacterSkillQueueEntry? {
        return currentEntries.first
    }
    
    public var last: ECKCharacterSkillQueueEntry? {
        return currentEntries.last
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([ECKCharacterSkillQueueEntry].self)
        self.loadedEntries = entries
    }
    
    private init() {
        self.loadedEntries = [.dummy1, .dummy2]
    }
    
    public static func == (lhs: ECKCharacterSkillQueue, rhs: ECKCharacterSkillQueue) -> Bool {
        return lhs.loadedEntries == rhs.loadedEntries
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(loadedEntries)
    }
    
}

public class ECKCharacterSkillQueueEntry: Decodable, Equatable, Identifiable, Hashable {
    
    private enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case finishDate = "finish_date"
        case finishLevel = "finished_level"
        case skill = "skill_id"
        case endSP = "level_end_sp"
    }
    
    public let startDate: Date?
    public let finishDate: Date?
    public let finishLevel: Int
    public let endSP: Int?
    public let skill: ECKCharacterSkill
    
    public static let dummy1: ECKCharacterSkillQueueEntry = .init(startDate: Date() - .fromHours(hours: 5),
                                                                  finishDate: Date().addingTimeInterval(.fromSeconds(seconds: 15)),
                                                                  finishLevel: 3,
                                                                  endSP: 5120000,
                                                                  skill: .dummy1)
    
    public static let dummy2: ECKCharacterSkillQueueEntry = .init(startDate: Date() - .fromHours(hours: 5),
                                                                  finishDate: Date().addingTimeInterval(.fromHours(hours: 23)).addingTimeInterval(.fromDays(days: 11)),
                                                                  finishLevel: 4,
                                                                  endSP: 512000,
                                                                  skill: .dummy1)
    
    public var id: String {
        return skill.skillId.description + "." + finishLevel.description
    }
    
    public var remainingTime: TimeInterval? {
        guard let finishDate else {
            return nil
        }
        
        return finishDate.timeIntervalSince(Date())
    }
    
    public var totalTime: TimeInterval? {
        guard let finishDate, let startDate else {
            return nil
        }
        
        return finishDate.timeIntervalSince(startDate)
    }
    
    internal init(startDate: Date?,
                  finishDate: Date?,
                  finishLevel: Int,
                  endSP: Int?,
                  skill: ECKCharacterSkill) {
        self.startDate = startDate
        self.finishDate = finishDate
        self.finishLevel = finishLevel
        self.endSP = endSP
        self.skill = skill
    }
    
    public static func == (lhs: ECKCharacterSkillQueueEntry, rhs: ECKCharacterSkillQueueEntry) -> Bool {
        return lhs.finishDate == rhs.finishDate
            && lhs.finishLevel == rhs.finishLevel
            && lhs.skill == rhs.skill
            && lhs.startDate == rhs.startDate
            && lhs.endSP == rhs.endSP
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
        hasher.combine(finishDate)
        hasher.combine(finishLevel)
        hasher.combine(skill)
        hasher.combine(endSP)
    }
    
}
