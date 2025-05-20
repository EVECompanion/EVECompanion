//
//  ECKPlanetSchematic.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.10.24.
//

import Foundation

public class ECKPlanetSchematic: Decodable, Identifiable, Hashable {
    
    public var id: Int {
        return schematicId
    }
    
    public let schematicId: Int
    public let inputs: [ECKPlanetSchematicInOut]
    public let output: ECKPlanetSchematicInOut
    public let cycleTime: Int
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let schematicId = try container.decode(Int.self)
        self.init(schematicId: schematicId)
    }
    
    convenience init(schematicId: Int) {
        let schematicData = ECKSDEManager.shared.getSchematicData(schematicId: schematicId)
        self.init(schematicId: schematicId,
                  data: schematicData)
    }
    
    init(schematicId: Int, data: (cycleTime: Int, inouts: [ECKSDEManager.FetchedSchematicData])) {
        self.schematicId = schematicId
        self.cycleTime = data.cycleTime
        
        self.inputs = data.inouts.filter({ $0.isInput }).map({ input in
            return .init(data: input)
        })
        
        if let outputData = data.inouts.first(where: { $0.isInput == false }) {
            self.output = .init(data: outputData)
        } else {
            logger.error("Cannot find output for schematic \(schematicId)")
            self.output = .init(item: .init(typeId: 999999999999),
                                quantity: 0)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(schematicId)
        hasher.combine(inputs)
        hasher.combine(output)
        hasher.combine(cycleTime)
    }
    
    public static func == (lhs: ECKPlanetSchematic, rhs: ECKPlanetSchematic) -> Bool {
        return lhs.schematicId == rhs.schematicId
        && lhs.inputs == rhs.inputs
        && lhs.output == rhs.output
        && lhs.cycleTime == rhs.cycleTime
    }
    
}

public class ECKPlanetSchematicInOut: Hashable {
    
    public let item: ECKItem
    public let quantity: Int
    
    convenience init(data: ECKSDEManager.FetchedSchematicData) {
        self.init(item: ECKItem(typeId: data.typeId),
                  quantity: data.quantity)
    }
    
    init(item: ECKItem, quantity: Int) {
        self.item = item
        self.quantity = quantity
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(item.id)
        hasher.combine(quantity)
    }
    
    public static func == (lhs: ECKPlanetSchematicInOut, rhs: ECKPlanetSchematicInOut) -> Bool {
        return lhs.item.id == rhs.item.id
        && lhs.quantity == rhs.quantity
    }
    
}
