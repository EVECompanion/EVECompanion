//
//  ECKSearchResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

final class ECKSearchResource: ECKWebResource<ECKSearchResponse>, @unchecked Sendable {
    
    init(searchText: String,
         token: ECKToken,
         categories: Set<ECKSearchCategory>,
         strict: Bool = false) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/search/",
                   token: token,
                   requiredScope: nil,
                   requiredCorpRoles: [],
                   queryItems: [
                    .init(name: "categories", value: categories.map(\.rawValue).sorted().joined(separator: ",")),
                    .init(name: "search", value: searchText),
                    .init(name: "strict", value: strict.description)
                   ],
                   headers: ["X-Compatibility-Date": "2026-05-17"])
    }
    
    convenience init(mailRecipientSearchText searchText: String, token: ECKToken) {
        self.init(searchText: searchText,
                  token: token,
                  categories: [.alliance, .character, .corporation])
    }
}
