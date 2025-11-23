//
//  ECKUpdateMailResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

struct ECKUpdateMailRequest: Encodable {
    let read: Bool
}

class ECKUpdateMailResource: ECKWebResource<ECKEmptyResponse> {
    
    init(token: ECKToken, mailId: Int, read: Bool) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/mail/\(mailId.description)/",
                   token: token,
                   requiredScope: .organizeMail,
                   method: .put,
                   body: ECKUpdateMailRequest(read: read))
    }
    
}
