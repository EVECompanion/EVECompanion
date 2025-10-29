//
//  ECKCharacterSkill.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 10.05.24.
//

import Foundation

public class ECKCharacterSkill: Codable, Hashable {
    
    public let skillId: Int
    public let name: String
    public let category: String
    public let primaryAttribute: String
    public let secondaryAttribute: String
    public let multiplier: Double
    
    public static let dummy1: ECKCharacterSkill = .init(skillId: 24311,
                                                        name: "Amarr Carrier",
                                                        category: "Spaceship Command",
                                                        primaryAttribute: "Perception",
                                                        secondaryAttribute: "Willpower",
                                                        multiplier: 14.0)
    
    public static let dummy2: ECKCharacterSkill = .init(skillId: 3347,
                                                        name: "Amarr Titan",
                                                        category: "Spaceship Command",
                                                        primaryAttribute: "Perception",
                                                        secondaryAttribute: "Willpower",
                                                        multiplier: 15.0)
    
    internal init(skillId: Int, 
                  name: String,
                  category: String,
                  primaryAttribute: String,
                  secondaryAttribute: String,
                  multiplier: Double) {
        self.skillId = skillId
        self.name = name
        self.category = category
        self.primaryAttribute = primaryAttribute
        self.secondaryAttribute = secondaryAttribute
        self.multiplier = multiplier
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.skillId = try container.decode(Int.self)
        let skillData = ECKSDEManager.shared.getSkill(skillId: skillId)
        self.name = skillData.skillName
        self.category = skillData.category
        self.primaryAttribute = skillData.primaryAttribute
        self.secondaryAttribute = skillData.secondaryAttribute
        self.multiplier = skillData.multiplier
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(skillId)
    }
    
    public static func == (lhs: ECKCharacterSkill, rhs: ECKCharacterSkill) -> Bool {
        return lhs.skillId == rhs.skillId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(skillId)
    }
    
}
