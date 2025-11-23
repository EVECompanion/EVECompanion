//
//  ECKImageInfoResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.11.24.
//

import Foundation

class ECKImageInfoResource: ECKWebResource<[String]> {
    
    init(category: String, id: Int) {
        super.init(host: .image,
                   endpoint: "/\(category)/\(id.description)/",
                   requiredScope: nil)
    }
    
}
