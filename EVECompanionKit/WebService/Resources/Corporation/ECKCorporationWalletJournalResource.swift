//
//  ECKCorporationWalletJournalResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.05.26.
//

import Foundation

class ECKCorporationWalletJournalResource: ECKWebResource<[ECKWalletJournalEntry]>, @unchecked Sendable {
    
    init(corporationId: Int, division: Int, page: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/wallets/\(division)/journal",
            token: token,
            requiredScope: .corpReadWallets,
            requiredCorpRoles: [.Accountant, .Junior_Accountant],
            currentCorpRoles: currentRoles,
            queryItems: [.init(name: "page", value: "\(page)")],
            headers: ["X-Compatibility-Date": "2026-05-06"]
        )
    }
    
}
