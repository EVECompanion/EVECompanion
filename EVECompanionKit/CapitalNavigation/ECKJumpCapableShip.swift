//
//  ECKJumpCapableShip.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.03.25.
//

import Foundation

public class ECKJumpCapableShip: Hashable, Identifiable, Codable {
    
    public var id: Int {
        return typeId
    }
    
    public let typeId: Int
    public let name: String
    public let groupId: Int
    public let groupName: String
    public let baseJumpRange: Double
    public let fuelConsumption: Double
    
    public var isJumpFreighter: Bool {
        return groupId == 902
    }
    
    convenience init(typeId: Int) {
        let data = ECKSDEManager.shared.jumpCapableShip(with: typeId)
        self.init(typeId: data.typeId,
                  name: data.name,
                  groupId: data.groupId,
                  groupName: data.groupName,
                  baseJumpRange: data.baseJumpRange,
                  fuelConsumption: data.fuelConsumption)
    }
    
    init(typeId: Int, name: String, groupId: Int, groupName: String, baseJumpRange: Double, fuelConsumption: Double) {
        self.typeId = typeId
        self.name = name
        self.groupId = groupId
        self.groupName = groupName
        self.baseJumpRange = baseJumpRange
        self.fuelConsumption = fuelConsumption
    }
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let shipId = try container.decode(Int.self)
        self.init(typeId: shipId)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeId)
        hasher.combine(name)
        hasher.combine(groupId)
        hasher.combine(groupName)
        hasher.combine(baseJumpRange)
        hasher.combine(fuelConsumption)
    }
    
    public static func == (lhs: ECKJumpCapableShip, rhs: ECKJumpCapableShip) -> Bool {
        return lhs.typeId == rhs.typeId
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(typeId)
    }
    
}
