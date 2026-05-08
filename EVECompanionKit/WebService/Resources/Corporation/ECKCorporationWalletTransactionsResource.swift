//
//  ECKCorporationWalletTransactionsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 29.04.26.
//

import Foundation

class ECKCorporationWalletTransactionsResource: ECKWebResource<[ECKWalletTransactionEntry]>, @unchecked Sendable {
    
    static let requiredCorpRoles: [ECKCorporationRole] = [.Accountant, .Junior_Accountant]
    
    init(corporationId: Int, division: Int, fromId: Int? = nil, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        var queryItems = [URLQueryItem]()
        
        if let fromId {
            queryItems.append(.init(name: "from_id", value: "\(fromId)"))
        }
        
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/wallets/\(division)/transactions/",
            token: token,
            requiredScope: .corpReadWallets,
            requiredCorpRoles: Self.requiredCorpRoles,
            currentCorpRoles: currentRoles,
            queryItems: queryItems,
            headers: ["X-Compatibility-Date": "2026-04-29"]
        )
    }
    
}
