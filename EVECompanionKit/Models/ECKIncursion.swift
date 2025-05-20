//
//  ECKIncursion.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public class ECKIncursion: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case constellation = "constellation_id"
        case faction = "faction_id"
        case hasBoss = "has_boss"
        case infestedSolarSystems = "infested_solar_systems"
        case influence
        case stagingSolarSystem = "staging_solar_system_id"
        case state
        case type
    }
    
    public let constellation: ECKConstellation
    public let faction: ECKFaction
    public let hasBoss: Bool
    public let infestedSolarSystems: [ECKSolarSystem]
    public let influence: Float
    public let stagingSolarSystem: ECKSolarSystem
    public let state: ECKIncursionState
    public let type: String
    
    public var id: Int {
        return stagingSolarSystem.solarSystemId
    }
    
}
