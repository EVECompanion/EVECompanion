//
//  ECKCharacterWalletJournalResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

class ECKCharacterWalletJournalResource: ECKWebResource<[ECKWalletJournalEntry]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v6/characters/\(token.characterId)/wallet/journal/",
                   token: token)
    }
    
}
