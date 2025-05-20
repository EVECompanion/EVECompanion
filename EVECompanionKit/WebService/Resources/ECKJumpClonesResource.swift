//
//  ECKJumpClonesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import Foundation

class ECKJumpClonesResource: ECKWebResource<ECKJumpClones> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v4/characters/\(token.characterId)/clones/",
                   token: token)
    }
    
}
