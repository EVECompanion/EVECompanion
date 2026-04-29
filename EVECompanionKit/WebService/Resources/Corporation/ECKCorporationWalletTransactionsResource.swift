//
//  ECKCorporationWalletTransactionsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 29.04.26.
//

import Foundation

class ECKCorporationWalletTransactionsResource: ECKWebResource<[ECKWalletTransactionEntry]>, @unchecked Sendable {
    
    init(corporationId: Int, division: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/wallets/\(division)/transactions/",
            token: token,
            requiredScope: .corpReadWallets,
            requiredCorpRoles: [.Accountant, .Junior_Accountant],
            currentCorpRoles: currentRoles,
            headers: ["X-Compatibility-Date": "2026-04-29"]
        )
    }
    
}
