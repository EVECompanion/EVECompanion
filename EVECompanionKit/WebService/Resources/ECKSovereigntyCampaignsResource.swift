//
//  ECKSovereigntyCampaignsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 02.07.24.
//

import Foundation

class ECKSovereigntyCampaignsResource: ECKWebResource<[ECKSovereigntyCampaign]> {
    
    init(etag: String?) {
        var headers: [String: String] = [:]
        
        if let etag {
            headers["If-None-Match"] = etag
        }
        
        super.init(host: .esi,
                   endpoint: "/v1/sovereignty/campaigns/",
                   requiredScope: nil,
                   headers: headers)
    }
    
}
