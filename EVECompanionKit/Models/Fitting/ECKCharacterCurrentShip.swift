//
//  ECKCharacterCurrentShip.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.10.25.
//

import Foundation

public class ECKCharacterCurrentShip: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case shipName = "ship_name"
        case ship = "ship_type_id"
    }
    
    public let shipName: String
    public let shipType: ECKItem
    
    static let dummy: ECKCharacterCurrentShip = {
        return .init(shipName: "EVECompanion's Avatar",
                     shipType: .init(typeId: 11567))
    }()
    
    init(shipName: String, shipType: ECKItem) {
        self.shipName = shipName
        self.shipType = shipType
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.shipName = try container.decode(String.self, forKey: .shipName)
        self.shipType = try container.decode(ECKItem.self, forKey: .ship)
    }
    
}
