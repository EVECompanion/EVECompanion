//
//  ECKSDEVersionResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.08.24.
//

import Foundation

class ECKSDEVersionResource: ECKWebResource<ECKSDEVersion> {
    
    init() {
        super.init(host: .evecompanionAPI,
                   endpoint: "/v2/version")
    }
    
}
