//
//  ECKPublicCharacterInfo.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

import Foundation

public final class ECKPublicCharacterInfo: Decodable, Equatable, Hashable, Sendable {
    
    private enum CodingKeys: String, CodingKey {
        case allianceId = "alliance_id"
        case birthday
        case bloodlineId = "bloodline_id"
        case corporationId = "corporation_id"
        case description
        case factionId = "faction_id"
        case gender
        case name
        case raceId = "race_id"
        case securityStatus = "security_status"
        case title
    }
    
    public enum ECKCharacterGender: String, Codable, Sendable {
        case male
        case female
    }
    
    static let dummy = ECKPublicCharacterInfo()
    
    public let allianceId: Int?
    public let birthday: Date
    let bloodlineId: Int
    public let corporationId: Int
    public let description: String?
    let factionId: Int?
    public let gender: ECKCharacterGender
    public let name: String
    let raceId: Int
    public let securityStatus: Float?
    public let title: String?
    
    private init() {
        self.allianceId = 498125261
        self.birthday = Date()
        self.bloodlineId = 0
        self.corporationId = 1018389948
        self.description = "This is a character description."
        self.factionId = nil
        self.gender = .male
        self.name = "EVECompanion"
        self.raceId = 0
        self.securityStatus = -10.0
        self.title = nil
    }
    
    public static func == (lhs: ECKPublicCharacterInfo, rhs: ECKPublicCharacterInfo) -> Bool {
        return lhs.allianceId == rhs.allianceId
        && lhs.birthday == rhs.birthday
        && lhs.bloodlineId == rhs.bloodlineId
        && lhs.corporationId == rhs.corporationId
        && lhs.description == rhs.description
        && lhs.gender == rhs.gender
        && lhs.name == rhs.name
        && lhs.raceId == rhs.raceId
        && lhs.securityStatus == rhs.securityStatus
        && lhs.title == rhs.title
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(allianceId)
        hasher.combine(birthday)
        hasher.combine(bloodlineId)
        hasher.combine(corporationId)
        hasher.combine(description)
        hasher.combine(gender)
        hasher.combine(name)
        hasher.combine(raceId)
        hasher.combine(securityStatus)
        hasher.combine(title)
    }
    
}
