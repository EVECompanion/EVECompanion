//
//  ECKCharacterWalletResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

class ECKCharacterWalletResource: ECKWebResource<Double>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/wallet/",
                   token: token,
                   requiredScope: .readCharacterWallet)
    }
    
}
