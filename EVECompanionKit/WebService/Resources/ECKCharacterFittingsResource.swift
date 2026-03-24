//
//  ECKCharacterFittingsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

class ECKCharacterFittingsResource: ECKWebResource<[ESIFitting]>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/fittings/",
                   token: token)
    }
    
}
