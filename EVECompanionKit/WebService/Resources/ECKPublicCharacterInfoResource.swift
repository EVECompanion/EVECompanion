//
//  ECKPublicCharacterInfoResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

class ECKPublicCharacterInfoResource: ECKWebResource<ECKPublicCharacterInfo> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v5/characters/\(token.characterId)",
                   token: token,
                   requiredScope: nil)
    }
    
}
