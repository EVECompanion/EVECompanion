//
//  ECKCharacterWalletTransactionResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

class ECKCharacterWalletTransactionResource: ECKWebResource<[ECKWalletTransactionEntry]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/wallet/transactions/",
                   token: token)
    }
    
}
