//
//  ECKFetchMailBodyResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKFetchMailBodyResponse: Decodable {
    let body: String?
}

class ECKFetchMailBodyResource: ECKWebResource<ECKFetchMailBodyResponse> {
    
    init(token: ECKToken, mailId: Int) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/mail/\(mailId.description)/",
                   token: token)
    }
    
}
