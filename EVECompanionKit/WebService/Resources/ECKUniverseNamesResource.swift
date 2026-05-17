//
//  ECKUniverseNamesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

struct ECKUniverseNameResponse: Decodable, Sendable {
    let category: String
    let id: Int
    let name: String
}

final class ECKUniverseNamesResource: ECKWebResource<[ECKUniverseNameResponse]>, @unchecked Sendable {
    
    private struct UniverseNamesRequest: Encodable {
        let ids: [Int]
        
        init(ids: [Int]) {
            self.ids = Array(Set(ids))
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(ids)
        }
    }
    
    init(ids: [Int]) {
        super.init(host: .esi,
                   endpoint: "/universe/names/",
                   requiredScope: nil,
                   requiredCorpRoles: [],
                   headers: ["X-Compatibility-Date": "2026-05-17"],
                   method: .post,
                   body: UniverseNamesRequest(ids: ids))
    }
}
