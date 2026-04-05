//
//  ECKCorporationContractResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.03.26.
//

import Foundation

class ECKCorporationContractResource: ECKWebResource<[ECKContract]>, @unchecked Sendable {
    
    init(corporationId: Int, page: Int, token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/corporations/\(corporationId)/contracts",
                   token: token,
                   requiredScope: .corpReadContracts,
                   requiredCorpRole: [],
                   queryItems: [.init(name: "page", value: "\(page)")],
                   headers: ["X-Compatibility-Date": "2026-03-25"])
    }
    
}
