//
//  ECKCorporationIndustryJobsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.04.26.
//

import Foundation

class ECKCorporationIndustryJobsResource: ECKWebResource<[ECKIndustryJob]>, @unchecked Sendable {
    
    init(corporationId: Int, page: Int, token: ECKToken) {
        super.init(
            host: .esi,
            endpoint: "/corporations/\(corporationId)/industry/jobs",
            token: token,
            requiredScope: .corpReadJobs,
            requiredCorpRole: [.Factory_Manager],
            queryItems: [.init(name: "page", value: "\(page)")],
            headers: ["X-Compatibility-Date": "2026-04-19"]
        )
    }
    
}
