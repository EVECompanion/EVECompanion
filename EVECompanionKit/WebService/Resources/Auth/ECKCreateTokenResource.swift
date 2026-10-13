//
//  ECKCreateTokenResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

class ECKCreateTokenResource: ECKWebResource<ECKToken>, @unchecked Sendable {
    
    init(clientId: String, codeVerifier: String, code: String) {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Host"] = "login.eveonline.com"
        
        let body = ECKOAuthTokenFormEncoder.encode([
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "code_verifier": codeVerifier
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
