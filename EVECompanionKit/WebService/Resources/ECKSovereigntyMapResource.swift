//
//  ECKSovereigntyMapResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.03.25.
//

import Foundation

class ECKSovereigntyMapResource: ECKWebResource<[ECKSolarSystemSovereignty]> {
    
    init(etag: String?) {
        var headers: [String: String] = [:]
        
        if let etag {
            headers["If-None-Match"] = etag
        }
        
        super.init(host: .esi,
                   endpoint: "/v1/sovereignty/map/",
                   requiredScope: nil,
                   requiredCorpRole: nil,
                   headers: headers)
    }
    
}
