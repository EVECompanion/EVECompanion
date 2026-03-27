//
//  ECKPlanetaryColoniesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.10.24.
//

import Foundation

class ECKPlanetaryColoniesResource: ECKWebResource<[ECKPlanetaryColony]>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/planets/",
                   token: token,
                   requiredScope: .managePlanets,
                   requiredCorpRole: [])
    }
    
}
