//
//  ECKTokenRefreshResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

class ECKTokenRefreshResource: ECKWebResource<ECKToken> {
    
    init(token: ECKToken, clientId: String) {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Host"] = "login.eveonline.com"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(.init(name: "grant_type", value: "refresh_token"))
        queryItems.append(.init(name: "refresh_token", value: token.refreshToken))
        queryItems.append(.init(name: "client_id", value: clientId))
        
        var urlComponents = URLComponents()
        urlComponents.queryItems = queryItems
        
        super.init(host: .eveLogin,
                   endpoint: "/v2/oauth/token",
                   headers: headers,
                   method: .post,
                   body: urlComponents.query?.data(using: .utf8))
    }
    
}
