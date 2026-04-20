//
//  ECKCharacterMarketOrdersResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

class ECKCharacterMarketOrdersResource: ECKWebResource<[ECKMarketOrder]>, @unchecked Sendable {
    
    init(token: ECKToken, page: Int) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/orders/",
                   token: token,
                   requiredScope: .readCharacterOrders,
                   requiredCorpRoles: [],
                   queryItems: [.init(name: "page", value: "\(page)")])
    }
    
}
