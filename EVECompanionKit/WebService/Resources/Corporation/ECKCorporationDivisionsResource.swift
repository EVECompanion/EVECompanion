//
//  ECKCorporationDivisionsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.04.26.
//

import Foundation

public struct ECKCorporationDivisionsResponse: Decodable, Sendable {
    
    public let hangar: [ECKCorporationDivision]
    public let wallet: [ECKCorporationDivision]
    
}

class ECKCorporationDivisionsResource: ECKWebResource<ECKCorporationDivisionsResponse>, @unchecked Sendable {
    
    init(corporationId: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/divisions/",
            token: token,
            requiredScope: .corpReadDivisions,
            requiredCorpRoles: [.Director],
            currentCorpRoles: currentRoles,
            headers: ["X-Compatibility-Date": "2026-04-28"]
        )
    }
    
}
