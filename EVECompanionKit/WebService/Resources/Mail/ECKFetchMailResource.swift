//
//  ECKFetchMailResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKFetchMailResource: ECKWebResource<[ECKMail]> {
    
    init(token: ECKToken, lastMailId: Int?) {
        var queryItems: [URLQueryItem] = []
        
        if let lastMailId {
            queryItems.append(.init(name: "last_mail_id", value: lastMailId.description))
        }
        
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/mail/",
                   token: token,
                   requiredScope: .readMail,
                   queryItems: queryItems)
    }
    
}
