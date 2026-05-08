//
//  ECKCharacterWalletTransactionResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

class ECKCharacterWalletTransactionResource: ECKWebResource<[ECKWalletTransactionEntry]>, @unchecked Sendable {
    
    init(token: ECKToken, fromId: Int? = nil) {
        var queryItems = [URLQueryItem]()
        
        if let fromId {
            queryItems.append(.init(name: "from_id", value: "\(fromId)"))
        }
        
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/wallet/transactions/",
                   token: token,
                   requiredScope: .readCharacterWallet,
                   requiredCorpRoles: [],
                   queryItems: queryItems)
    }
    
}
