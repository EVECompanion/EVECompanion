//
//  ECKCharacterAttributesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.06.24.
//

import Foundation

class ECKCharacterAttributesResource: ECKWebResource<ECKCharacterAttributes> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/attributes/",
                   token: token)
    }
    
}
