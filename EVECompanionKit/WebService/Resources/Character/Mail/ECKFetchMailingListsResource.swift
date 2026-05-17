//
//  ECKFetchMailingListsResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKFetchMailingListsResource: ECKWebResource<[ECKMailingList]>, @unchecked Sendable {
    
    init(token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/mail/lists/",
                   token: token,
                   requiredScope: .readMail,
                   requiredCorpRoles: [],
                   headers: ["X-Compatibility-Date": "2026-05-17"])
    }
    
}
