//
//  ECKMarketOrdersResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.11.25.
//

import Foundation

class ECKMarketOrdersResource: ECKWebResource<[ECKMarketOrder]> {
    
    init(typeId: Int, regionId: Int) {
        let headers: [String: String] = ["X-Compatibility-Date": "2025-11-11"]
        let requestRegionId: Int
        // In case the item is plex, override
        // the region to the plex market region
        if typeId == 44992 {
            requestRegionId = 19000001
        } else {
            requestRegionId = regionId
        }
        
        super.init(host: .esi,
                   endpoint: "/markets/\(requestRegionId)/orders",
                   requiredScope: nil,
                   queryItems: [
                    URLQueryItem(name: "type_id", value: "\(typeId)")
                   ],
                   headers: headers)
    }
    
}
