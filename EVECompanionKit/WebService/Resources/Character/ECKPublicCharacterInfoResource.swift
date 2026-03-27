//
//  ECKPublicCharacterInfoResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

class ECKPublicCharacterInfoResource: ECKWebResource<ECKPublicCharacterInfo>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v5/characters/\(token.characterId)",
                   token: token,
                   requiredScope: nil,
                   requiredCorpRole: [])
    }
    
}
