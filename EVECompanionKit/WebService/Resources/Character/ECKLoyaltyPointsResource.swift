//
//  ECKLoyaltyPointsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

class ECKLoyaltyPointsResource: ECKWebResource<[ECKLoyaltyPointsEntry]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/loyalty/points/",
                   token: token,
                   requiredScope: .readLoyalty,
                   requiredCorpRole: nil)
    }
    
}
