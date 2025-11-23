//
//  ECKServerStatusResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.05.25.
//

import Foundation

class ECKServerStatusResource: ECKWebResource<ECKServerStatus> {
    
    init(etag: String?) {
        var headers: [String: String] = [:]
        
        if let etag {
            headers["If-None-Match"] = etag
        }
        
        super.init(host: .esi,
                   endpoint: "/v2/status/",
                   requiredScope: nil,
                   headers: headers)
    }
    
}
