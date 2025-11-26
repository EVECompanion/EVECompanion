//
//  ECKCharacterIndustryJobsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import Foundation

class ECKCharacterIndustryJobsResource: ECKWebResource<[ECKIndustryJob]>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/industry/jobs/",
                   token: token,
                   requiredScope: .readCharacterJobs,
                   requiredCorpRole: nil)
    }
    
}
