//
//  ECKFetchMailingListsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class FetchMailingListsResource: ECKWebResource<[ECKMailingList]> {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)/mail/lists/",
                   token: token,
                   requiredScope: .readMail)
    }
    
}
