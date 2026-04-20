//
//  ECKCharacterCorpRolesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.04.26.
//

import Foundation

class ECKCharacterCorpRolesResource: ECKWebResource<ECKCorporationRoles>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(
            host: .esi,
            endpoint: "/characters/\(token.characterId)/roles",
            token: token,
            requiredScope: .characterReadCorpRoles,
            requiredCorpRoles: [],
            method: .get)
    }
    
}
