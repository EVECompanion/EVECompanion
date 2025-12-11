//
//  ECKSkillPlanRemap.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation

public class ECKSkillPlanRemap: Codable, Hashable {
    
    static private let baseAttributePoints: Int = 17
    
    public let charisma: Int
    public let intelligence: Int
    public let memory: Int
    public let perception: Int
    public let willpower: Int
    
    public init(charisma: Int,
                intelligence: Int,
                memory: Int,
                perception: Int,
                willpower: Int) {
        self.charisma = charisma
        self.intelligence = intelligence
        self.memory = memory
        self.perception = perception
        self.willpower = willpower
    }
    
    func value(attributeId: Int) -> Int {
        switch attributeId {
        case 164:
            return charisma + Self.baseAttributePoints
        case 165:
            return intelligence + Self.baseAttributePoints
        case 166:
            return memory + Self.baseAttributePoints
        case 167:
            return perception + Self.baseAttributePoints
        case 168:
            return willpower + Self.baseAttributePoints
        default:
            return Self.baseAttributePoints
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(charisma)
        hasher.combine(intelligence)
        hasher.combine(memory)
        hasher.combine(perception)
        hasher.combine(willpower)
    }
    
    public static func == (lhs: ECKSkillPlanRemap, rhs: ECKSkillPlanRemap) -> Bool {
        return lhs.charisma == rhs.charisma
        && lhs.intelligence == rhs.intelligence
        && lhs.memory == rhs.memory
        && lhs.perception == rhs.perception
        && lhs.willpower == rhs.willpower
    }
    
}
