//
//  ECKCharacterMiningLedgerResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import Foundation

class ECKCharacterMiningLedgerResource: ECKWebResource<[ECKMiningLedgerEntry]>, @unchecked Sendable {
    
    init(token: ECKToken, page: Int) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/mining/",
                   token: token,
                   requiredScope: .readCharacterMining,
                   requiredCorpRoles: [],
                   queryItems: [.init(name: "page", value: "\(page)")],
                   headers: ["X-Compatibility-Date": "2026-06-09"])
    }
    
}
