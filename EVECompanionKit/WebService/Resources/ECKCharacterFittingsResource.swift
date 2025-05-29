//
//  ECKCharacterFittingsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

class ECKCharacterFittingsResource: ECKWebResource<[ECKCharacterFitting]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/fittings/",
                   token: token)
    }
    
}
