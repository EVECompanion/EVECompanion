//
//  ECKCharacterAssetNamesResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

class ECKCharacterAssetNamesResource: ECKWebResource<[ECKAssetName]> {
    
    init(token: ECKToken, itemIds: [Int]) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/assets/names/",
                   token: token,
                   method: .post,
                   body: itemIds)
    }
    
}
