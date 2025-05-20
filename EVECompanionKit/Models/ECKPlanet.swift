//
//  ECKPlanet.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.10.24.
//

import Foundation

public class ECKPlanet: Decodable, Identifiable, Hashable {
    
    public let planetId: Int
    public let typeId: Int
    public let name: String
    public let type: ECKItem
    
    public var id: Int { planetId }
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let planetId = try container.decode(Int.self)
        self.init(planetId: planetId)
    }
    
    convenience init(planetId: Int) {
        let data = ECKSDEManager.shared.getPlanet(planetId: planetId)
        self.init(planetId: planetId, typeId: data.typeId, name: data.name)
    }
    
    init (planetId: Int, typeId: Int, name: String) {
        self.planetId = planetId
        self.typeId = typeId
        self.type = ECKItem(typeId: typeId)
        self.name = name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(planetId)
        hasher.combine(typeId)
        hasher.combine(name)
        hasher.combine(type)
    }
    
    public static func == (lhs: ECKPlanet, rhs: ECKPlanet) -> Bool {
        return lhs.planetId == rhs.planetId
        && lhs.typeId == rhs.typeId
        && lhs.name == rhs.name
        && lhs.type == rhs.type
    }
    
}
