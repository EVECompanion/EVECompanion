//
//  ECKCapitalJumpRoute.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.03.25.
//

import Foundation
import simd

public class ECKCapitalJumpRoute: Identifiable, Equatable, Codable {
    
    private enum CodingKeys: CodingKey {
        case id
        case name
        case destinationSystems
        case avoidanceSystems
        case ship
        case jdcSkillLevel
        case jfcSkillLevel
        case jfSkillLevel
        case route
    }
    
    public class SystemEntry: Identifiable, Codable, Equatable {
        
        public let id: UUID = UUID()
        public var system: ECKSolarSystem
        
        public init(system: ECKSolarSystem) {
            self.system = system
        }
        
        required public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.system = try container.decode(ECKSolarSystem.self)
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(system)
        }
        
        public static func == (lhs: ECKCapitalJumpRoute.SystemEntry, rhs: ECKCapitalJumpRoute.SystemEntry) -> Bool {
            return lhs.id == rhs.id && lhs.system == rhs.system
        }
        
    }
    
    public let id: UUID
    public var name: String?
    public let destinationSystems: [SystemEntry]
    public let avoidanceSystems: [SystemEntry]
    public let ship: ECKJumpCapableShip
    public let jdcSkillLevel: Int
    public let jfcSkillLevel: Int
    public let jfSkillLevel: Int?
    public let route: [SystemEntry]?
    
    public var totalDistance: Double? {
        guard let route, route.count >= 2 else {
            return nil
        }
        
        let jumps = zip(route.dropFirst(), route.dropLast())
        
        var distance: Double = 0
        
        for jump in jumps {
            distance += self.distance(from: jump.0, to: jump.1)
        }
        
        return distance
    }
    
    public var totalFuelConsumption: Int? {
        guard let route, route.count >= 2 else {
            return nil
        }
        
        let jumps = zip(route.dropFirst(), route.dropLast())
        
        var distance: Int = 0
        
        for jump in jumps {
            distance += self.fuelConsumption(from: jump.0, to: jump.1)
        }
        
        return distance
    }
    
    public func distance(from: SystemEntry, to: SystemEntry) -> Double {
        return Double(simd_distance(from.system.position, to.system.position))
    }
    
    public func fuelConsumption(from: SystemEntry, to: SystemEntry) -> Int {
        let distanceInLY: Double = distance(from: from, to: to) / CCP_LY_FACTOR
        let baseFuelConsumption: Double = ship.fuelConsumption
        
        var isotopesUsed: Double = distanceInLY * baseFuelConsumption * (1 - 0.1 * Double(self.jfcSkillLevel))
        
        if ship.isJumpFreighter, let jfSkillLevel {
            isotopesUsed *= (1 - 0.1 * Double(jfSkillLevel))
        }
        
        return Int(round(isotopesUsed))
    }
    
    public static let dummy1: ECKCapitalJumpRoute = .init(
        id: UUID(),
        name: "Escape from Amarr",
        destinationSystems: [
            .init(solarSystemId: 30002187),
            .init(solarSystemId: 30045332)
        ],
        avoidanceSystems: [],
        jdcSkillLevel: 5,
        jfcSkillLevel: 5,
        jfSkillLevel: 5,
        ship: .init(typeId: 11567),
        route: [
            .init(solarSystemId: 30000142),
            .init(solarSystemId: 30002659),
            .init(solarSystemId: 30002053)
        ])
    
    public static let dummy2: ECKCapitalJumpRoute = .init(
        id: UUID(),
        name: nil,
        destinationSystems: [
            .init(solarSystemId: 30002187),
            .init(solarSystemId: 30045332)
        ],
        avoidanceSystems: [],
        jdcSkillLevel: 5,
        jfcSkillLevel: 5,
        jfSkillLevel: 5,
        ship: .init(typeId: 42241),
        route: [
            .init(solarSystemId: 30000142),
            .init(solarSystemId: 30002659),
            .init(solarSystemId: 30002053)
        ])
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.destinationSystems = try container.decode([SystemEntry].self, forKey: .destinationSystems)
        self.avoidanceSystems = try container.decode([SystemEntry].self, forKey: .avoidanceSystems)
        self.ship = try container.decode(ECKJumpCapableShip.self, forKey: .ship)
        self.jdcSkillLevel = try container.decode(Int.self, forKey: .jdcSkillLevel)
        self.jfcSkillLevel = try container.decode(Int.self, forKey: .jfcSkillLevel)
        self.jfSkillLevel = try container.decodeIfPresent(Int.self, forKey: .jfSkillLevel)
        self.route = try container.decodeIfPresent([SystemEntry].self, forKey: .route)
    }
    
    convenience init(id: UUID? = nil,
                     name: String? = nil,
                     destinationSystems: [SystemEntry],
                     avoidanceSystems: [SystemEntry],
                     jdcSkillLevel: Int,
                     jfcSkillLevel: Int,
                     jfSkillLevel: Int?,
                     ship: ECKJumpCapableShip,
                     route: [SystemEntry]?) {
        self.init(id: id,
                  name: name,
                  destinationSystems: destinationSystems.map({ $0.system }),
                  avoidanceSystems: avoidanceSystems.map({ $0.system }),
                  jdcSkillLevel: jdcSkillLevel,
                  jfcSkillLevel: jfcSkillLevel,
                  jfSkillLevel: jfSkillLevel,
                  ship: ship,
                  route: route?.map({ $0.system }))
    }
    
    convenience init(id: UUID? = nil,
                     name: String? = nil,
                     destinationSystems: [SystemEntry],
                     avoidanceSystems: [SystemEntry],
                     jdcSkillLevel: Int,
                     jfcSkillLevel: Int,
                     jfSkillLevel: Int?,
                     ship: ECKJumpCapableShip,
                     route: [ECKSolarSystem]?) {
        self.init(id: id,
                  name: name,
                  destinationSystems: destinationSystems.map({ $0.system }),
                  avoidanceSystems: avoidanceSystems.map({ $0.system }),
                  jdcSkillLevel: jdcSkillLevel,
                  jfcSkillLevel: jfcSkillLevel,
                  jfSkillLevel: jfSkillLevel,
                  ship: ship,
                  route: route)
    }
    
    init(id: UUID? = nil,
         name: String? = nil,
         destinationSystems: [ECKSolarSystem],
         avoidanceSystems: [ECKSolarSystem],
         jdcSkillLevel: Int,
         jfcSkillLevel: Int,
         jfSkillLevel: Int?,
         ship: ECKJumpCapableShip,
         route: [ECKSolarSystem]?) {
        self.id = id ?? UUID()
        self.name = name
        self.destinationSystems = destinationSystems.map({ SystemEntry(system: $0) })
        self.avoidanceSystems = avoidanceSystems.map({ SystemEntry(system: $0) })
        self.jdcSkillLevel = jdcSkillLevel
        self.jfcSkillLevel = jfcSkillLevel
        self.jfSkillLevel = jfSkillLevel
        self.ship = ship
        self.route = route?.map({ SystemEntry(system: $0) })
    }
    
    public static func == (lhs: ECKCapitalJumpRoute, rhs: ECKCapitalJumpRoute) -> Bool {
        return lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.destinationSystems == rhs.destinationSystems
        && lhs.avoidanceSystems == rhs.avoidanceSystems
        && lhs.ship == rhs.ship
        && lhs.jdcSkillLevel == rhs.jdcSkillLevel
        && lhs.jfcSkillLevel == rhs.jfcSkillLevel
        && lhs.jfSkillLevel == rhs.jfSkillLevel
        && lhs.route == rhs.route
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encode(self.destinationSystems, forKey: .destinationSystems)
        try container.encode(self.avoidanceSystems, forKey: .avoidanceSystems)
        try container.encode(self.ship, forKey: .ship)
        try container.encode(jdcSkillLevel, forKey: .jdcSkillLevel)
        try container.encode(jfcSkillLevel, forKey: .jfcSkillLevel)
        try container.encodeIfPresent(jfSkillLevel, forKey: .jfSkillLevel)
        try container.encodeIfPresent(self.route, forKey: .route)
    }
    
}
