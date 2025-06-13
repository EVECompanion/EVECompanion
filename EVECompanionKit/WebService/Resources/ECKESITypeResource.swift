//
//  ECKESITypeResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 09.06.25.
//

import Foundation

class ECKESITypeResource: ECKWebResource<String> {
    
    init(typeId: Int) {
        super.init(host: .esi, endpoint: "/universe/types/\(typeId)/")
    }
    
}
