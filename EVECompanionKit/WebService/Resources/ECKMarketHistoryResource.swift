//
//  ECKMarketHistoryResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 12.11.25.
//

import Foundation

class ECKMarketHistoryResource: ECKWebResource<[ECKMarketHistoryEntry]> {
    
    init(regionId: Int, typeId: Int) {
        super.init(host: .esi,
                   endpoint: "/markets/\(regionId)/history",
                   queryItems: [.init(name: "type_id", value: "\(typeId)")],
                   headers: ["X-Compatibility-Date": "2025-11-11"],
                   method: .get)
    }
    
}
