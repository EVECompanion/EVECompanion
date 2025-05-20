//
//  ECKCharacterSkillsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 09.05.24.
//

import Foundation

class ECKCharacterSkillsResource: ECKWebResource<ECKCharacterSkills> {
    
    internal init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v4/characters/\(token.characterId)/skills/",
                   token: token)
    }
    
}
