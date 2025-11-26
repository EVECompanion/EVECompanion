//
//  ECKCharacterMarketOrdersResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

class ECKCharacterMarketOrdersResource: ECKWebResource<[ECKCharacterMarketOrder]>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/orders/",
                   token: token,
                   requiredScope: .readCharacterOrders,
                   requiredCorpRole: nil)
    }
    
}
