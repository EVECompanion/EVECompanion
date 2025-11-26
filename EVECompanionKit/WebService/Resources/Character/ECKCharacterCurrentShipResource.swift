//
//  ECKCharacterCurrentShipResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.10.25.
//

import Foundation

class ECKCharacterCurrentShipResource: ECKWebResource<ECKCharacterCurrentShip> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/ship",
                   token: token,
                   requiredScope: .readShipType,
                   requiredCorpRole: nil,
                   headers: ["X-Compatibility-Date": "2025-09-30"])
    }
    
}
