//
//  ECKCorporationIndustryJobsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.04.26.
//

import Foundation

class ECKCorporationIndustryJobsResource: ECKWebResource<[ECKIndustryJob]>, @unchecked Sendable {
    
    static let requiredCorpRoles: [ECKCorporationRole] = [.Factory_Manager]
    
    init(corporationId: Int, page: Int, token: ECKToken, currentRoles: [ECKCorporationRole]) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/industry/jobs",
            token: token,
            requiredScope: .corpReadJobs,
            requiredCorpRoles: Self.requiredCorpRoles,
            currentCorpRoles: currentRoles,
            queryItems: [.init(name: "page", value: "\(page)")],
            headers: ["X-Compatibility-Date": "2026-04-19"]
        )
    }
    
}
