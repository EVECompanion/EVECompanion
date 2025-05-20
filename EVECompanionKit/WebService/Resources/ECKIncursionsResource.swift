//
//  ECKIncursionsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

class ECKIncursionsResource: ECKWebResource<[ECKIncursion]> {
    
    init() {
        super.init(host: .esi,
                   endpoint: "/v1/incursions/")
    }
    
}
