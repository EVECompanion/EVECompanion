//
//  ECKCorporationMarketOrdersResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 27.03.26.
//

import Foundation

class ECKCorporationMarketOrdersResource: ECKWebResource<[ECKMarketOrder]>, @unchecked Sendable {
    
    static let requiredCorpRoles: [ECKCorporationRole] = [.Accountant, .Trader]
    
    init(corporationId: Int, page: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/orders",
            token: token,
            requiredScope: .corpReadOrders,
            requiredCorpRoles: Self.requiredCorpRoles,
            currentCorpRoles: currentRoles,
            queryItems: [.init(name: "page", value: "\(page)")],
            headers: ["X-Compatibility-Date": "2026-03-27"],
            method: .get
        )
    }
    
}
