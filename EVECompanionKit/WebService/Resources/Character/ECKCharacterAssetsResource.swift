//
//  ECKCharacterAssetsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

class ECKCharacterAssetsResource: ECKWebResource<[ECKAsset]> {
    
    init(token: ECKToken, page: Int) {
        super.init(host: .esi,
                   endpoint: "/v5/characters/\(token.characterId)/assets/",
                   token: token,
                   requiredScope: .readAssets,
                   requiredCorpRole: nil,
                   queryItems: [.init(name: "page", value: page.description)])
    }
    
}
