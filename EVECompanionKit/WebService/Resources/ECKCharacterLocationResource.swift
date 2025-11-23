//
//  ECKCharacterLocationResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.10.25.
//

import Foundation

class ECKCharacterLocationResource: ECKWebResource<ECKCharacterLocation> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/location",
                   token: token,
                   requiredScope: .readLocation,
                   headers: ["X-Compatibility-Date": "2025-09-30"])
    }
    
}
