//
//  ECKAssetName.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

class ECKAssetName: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name
    }
    
    let itemId: Int
    let name: String?
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.itemId = try container.decode(Int.self, forKey: .itemId)
        let name = try container.decode(String.self, forKey: .name)
        if name == "None" || name.isEmpty {
            self.name = nil
        } else {
            self.name = name
        }
    }
    
    init(itemId: Int, name: String?) {
        self.itemId = itemId
        self.name = name
    }
    
}
