//
//  ECKCharacterAttributes.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.06.24.
//

import Foundation

public class ECKCharacterAttributes: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case accruedRemapCooldownDate = "accrued_remap_cooldown_date"
        case bonusRemaps = "bonus_remaps"
        case charisma
        case intelligence
        case lastRemapDate = "last_remap_date"
        case memory
        case perception
        case willpower
    }
    
    public let accruedRemapCooldownDate: Date?
    public let bonusRemaps: Int?
    public let charisma: Int
    public let intelligence: Int
    public let lastRemapDate: Date?
    public let memory: Int
    public let perception: Int
    public let willpower: Int
    
    static let dummy: ECKCharacterAttributes = .init(accruedRemapCooldownDate: nil,
                                                     bonusRemaps: 1,
                                                     charisma: 17,
                                                     intelligence: 17,
                                                     lastRemapDate: Date() - .fromDays(days: 5),
                                                     memory: 17,
                                                     perception: 27,
                                                     willpower: 21)
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accruedRemapCooldownDate = try container.decodeIfPresent(Date.self, forKey: .accruedRemapCooldownDate)
        self.bonusRemaps = try container.decodeIfPresent(Int.self, forKey: .bonusRemaps)
        self.charisma = try container.decode(Int.self, forKey: .charisma)
        self.intelligence = try container.decode(Int.self, forKey: .intelligence)
        self.lastRemapDate = try container.decodeIfPresent(Date.self, forKey: .lastRemapDate)
        self.memory = try container.decode(Int.self, forKey: .memory)
        self.perception = try container.decode(Int.self, forKey: .perception)
        self.willpower = try container.decode(Int.self, forKey: .willpower)
    }
    
    init(accruedRemapCooldownDate: Date?, 
         bonusRemaps: Int?,
         charisma: Int,
         intelligence: Int,
         lastRemapDate: Date?,
         memory: Int,
         perception: Int,
         willpower: Int) {
        self.accruedRemapCooldownDate = accruedRemapCooldownDate
        self.bonusRemaps = bonusRemaps
        self.charisma = charisma
        self.intelligence = intelligence
        self.lastRemapDate = lastRemapDate
        self.memory = memory
        self.perception = perception
        self.willpower = willpower
    }
    
}
