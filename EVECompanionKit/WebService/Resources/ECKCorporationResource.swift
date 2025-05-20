//
//  ECKCorporationResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

class ECKCorporationResource: ECKWebResource<ECKOptionalResponse<ECKCorporation>> {
    
    init(corporationId: Int) {
        super.init(host: .esi,
                   endpoint: "/v5/corporations/\(corporationId.description)/")
    }
    
}
