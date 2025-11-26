//
//  ECKCreateTokenResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

class ECKCreateTokenResource: ECKWebResource<ECKToken> {
    
    init(clientId: String, codeVerifier: String, code: String) {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Host"] = "login.eveonline.com"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(.init(name: "grant_type", value: "authorization_code"))
        queryItems.append(.init(name: "code", value: code))
        queryItems.append(.init(name: "client_id", value: clientId))
        queryItems.append(.init(name: "code_verifier", value: codeVerifier))
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = queryItems
        
        super.init(host: .eveLogin,
                   endpoint: "/v2/oauth/token",
                   requiredScope: nil,
                   requiredCorpRole: nil,
                   headers: headers,
                   method: .post,
                   body: urlComponents.query?.data(using: .utf8))
    }
    
}
