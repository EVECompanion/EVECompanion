//
//  ECKWebResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

class ECKWebResource<DecodeTo: Decodable> {
    
    var host: Host
    var endpoint: String
    
    var queryItems: [URLQueryItem]
    
    var headers: [String: String]
    
    var method: ECKHTTPMethod
    var body: (any Encodable)?
    var token: ECKToken?
    var requiredScope: ECKAPIScope?
    var requiredCorpRole: ECKCorporationRole?
    
    @MainActor
    var tokenContainsRequiredScopes: Bool {
        guard let requiredScope,
              let token else {
            return true
        }
        
        return token.includesScope(scope: requiredScope)
    }
    
    var url: URL? {
        var components = URLComponents()
        
        components.scheme = "https"
        components.host = host.value
        components.path = endpoint
        components.queryItems = queryItems
        
        return components.url
    }
    
    init(host: Host,
         endpoint: String,
         token: ECKToken? = nil,
         requiredScope: ECKAPIScope?,
         requiredCorpRole: ECKCorporationRole?,
         queryItems: [URLQueryItem] = [],
         headers: [String: String] = [:],
         method: ECKHTTPMethod = .get,
         body: (any Encodable)? = nil) {
        self.host = host
        self.endpoint = endpoint
        self.token = token
        self.queryItems = queryItems
        self.headers = headers
        self.method = method
        self.body = body
    }
    
}
