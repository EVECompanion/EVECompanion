//
//  ECKTokenRefreshResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.10.26.
//

import Foundation

class ECKTokenRefreshResource: ECKWebResource<ECKToken>, @unchecked Sendable {

    init(token: ECKToken, clientId: String) {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Host"] = "login.eveonline.com"

        let body = ECKOAuthTokenFormEncoder.encode([
            "grant_type": "refresh_token",
            "refresh_token": token.refreshToken,
            "client_id": clientId
        ])

        super.init(host: .eveLogin,
                   endpoint: "/v2/oauth/token",
                   requiredScope: nil,
                   requiredCorpRoles: [],
                   headers: headers,
                   method: .post,
                   body: body)
    }

}
