//
//  ECKCharacterContractResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

import Foundation

class ECKCharacterContractResource: ECKWebResource<[ECKContract]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/contracts/",
                   token: token,
                   requiredScope: .readCharacterContracts,
                   requiredCorpRole: nil)
    }
    
}
