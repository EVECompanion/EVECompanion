//
//  ECKCharacterMarketOrdersResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

class ECKCharacterMarketOrdersResource: ECKWebResource<[ECKCharacterMarketOrder]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/orders/",
                   token: token,
                   requiredScope: .readCharacterOrders)
    }
    
}
