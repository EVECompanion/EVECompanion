//
//  ECKCharacterImplantResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.06.24.
//

import Foundation

class ECKCharacterImplantResource: ECKWebResource<[ECKItem]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/characters/\(token.characterId)/implants/",
                   token: token)
    }
    
}
