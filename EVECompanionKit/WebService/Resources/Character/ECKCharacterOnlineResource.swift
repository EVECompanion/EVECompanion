//
//  ECKCharacterOnlineResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.26.
//

import Foundation

class ECKCharacterOnlineResource: ECKWebResource<ECKCharacterOnline>, @unchecked Sendable {

    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/online",
                   token: token,
                   requiredScope: .readOnline,
                   requiredCorpRoles: [],
                   headers: ["X-Compatibility-Date": "2026-06-09"])
    }

}
