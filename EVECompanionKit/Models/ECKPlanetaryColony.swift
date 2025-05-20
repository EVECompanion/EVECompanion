//
//  ECKPlanetaryColony.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.10.24.
//

import Foundation

public class ECKPlanetaryColony: Decodable, Hashable {
    
    enum CodingKeys: String, CodingKey {
        case lastUpdate = "last_update"
        case numPins = "num_pins"
        case ownerId = "owner_id"
        case planet = "planet_id"
        case planetType = "planet_type"
        case solarSystem = "solar_system_id"
        case upgradeLevel = "upgrade_level"
    }
    
    public let lastUpdate: Date
    public let numPins: Int
    public let ownerId: Int
    public let planet: ECKPlanet
    public let planetType: ECKPlanetType
    public let solarSystem: ECKSolarSystem
    public let upgradeLevel: Int
    
    public static let dummy1: ECKPlanetaryColony = .init(lastUpdate: .init() - .fromHours(hours: 5),
                                                         numPins: 5,
                                                         ownerId: 2123087197,
                                                         planet: .init(planetId: 40009098),
                                                         planetType: .ice,
                                                         solarSystem: .jita,
                                                         upgradeLevel: 4)
    
    init(lastUpdate: Date,
         numPins: Int,
         ownerId: Int,
         planet: ECKPlanet,
         planetType: ECKPlanetType,
         solarSystem: ECKSolarSystem,
         upgradeLevel: Int) {
        self.lastUpdate = lastUpdate
        self.numPins = numPins
        self.ownerId = ownerId
        self.planet = planet
        self.planetType = planetType
        self.solarSystem = solarSystem
        self.upgradeLevel = upgradeLevel
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lastUpdate = try container.decode(Date.self, forKey: .lastUpdate)
        self.numPins = try container.decode(Int.self, forKey: .numPins)
        self.ownerId = try container.decode(Int.self, forKey: .ownerId)
        self.planet = try container.decode(ECKPlanet.self, forKey: .planet)
        self.planetType = try container.decode(ECKPlanetType.self, forKey: .planetType)
        self.solarSystem = try container.decode(ECKSolarSystem.self, forKey: .solarSystem)
        self.upgradeLevel = try container.decode(Int.self, forKey: .upgradeLevel)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lastUpdate)
        hasher.combine(numPins)
        hasher.combine(ownerId)
        hasher.combine(planet)
        hasher.combine(planetType)
        hasher.combine(solarSystem)
        hasher.combine(upgradeLevel)
    }
    
    public static func == (lhs: ECKPlanetaryColony, rhs: ECKPlanetaryColony) -> Bool {
        return lhs.lastUpdate == rhs.lastUpdate
        && lhs.numPins == rhs.numPins
        && lhs.ownerId == rhs.ownerId
        && lhs.planet == rhs.planet
        && lhs.planetType == rhs.planetType
        && lhs.solarSystem == rhs.solarSystem
        && lhs.upgradeLevel == rhs.upgradeLevel
    }
    
}
