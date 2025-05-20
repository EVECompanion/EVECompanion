//
//  ECKCharacterSkillqueueResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 10.05.24.
//

import Foundation

class ECKCharacterSkillqueueResource: ECKWebResource<ECKCharacterSkillQueue> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/skillqueue/",
                   token: token)
    }
    
}
