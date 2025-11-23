//
//  ECKCharacterJumpFatigueResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.07.24.
//

import Foundation

class ECKCharacterJumpFatigueResource: ECKWebResource<ECKJumpFatigue>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/fatigue/",
                   token: token,
                   requiredScope: .readFatigue)
    }
    
}
