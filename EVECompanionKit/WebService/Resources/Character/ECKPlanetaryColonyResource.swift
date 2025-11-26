//
//  ECKPlanetaryColonyResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.10.24.
//

import Foundation

class ECKPlanetaryColonyResource: ECKWebResource<ECKPlanetaryColonyDetails> {
    
    init(token: ECKToken, colonyId: String) {
        super.init(host: .esi,
                   endpoint: "/v3/characters/\(token.characterId)/planets/\(colonyId)/",
                   token: token,
                   requiredScope: .managePlanets,
                   requiredCorpRole: nil)
    }
    
}
