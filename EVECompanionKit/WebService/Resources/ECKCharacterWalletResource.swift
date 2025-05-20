//
//  ECKCharacterWalletResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

class ECKCharacterWalletResource: ECKWebResource<Double> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/wallet/",
                   token: token)
    }
    
}
