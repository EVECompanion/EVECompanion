//
//  ECKCorporationWalletsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.04.26.
//

import Foundation

class ECKCorporationWalletsResource: ECKWebResource<[ECKCorporationWalletDivision]>, @unchecked Sendable {
    
    init(corporationId: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/wallets/",
            token: token,
            requiredScope: .corpReadWallets,
            requiredCorpRoles: [.Accountant, .Junior_Accountant],
            currentCorpRoles: currentRoles,
            headers: ["X-Compatibility-Date": "2026-04-28"]
        )
    }
    
}
