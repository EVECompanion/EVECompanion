//
//  ESIFitting.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 23.06.25.
//

import Foundation

struct ESIFitting: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case description
        case fittingId = "fitting_id"
        case items
        case name
        case ship = "ship_type_id"
    }
    
    let description: String
    let fittingId: Int
    let items: [ECKCharacterFittingItem]
    let name: String
    let ship: ECKItem
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.fittingId = try container.decode(Int.self, forKey: .fittingId)
        self.items = try container.decode([ECKCharacterFittingItem].self, forKey: .items)
        self.name = try container.decode(String.self, forKey: .name)
        self.ship = try container.decode(ECKItem.self, forKey: .ship)
    }
    
}
