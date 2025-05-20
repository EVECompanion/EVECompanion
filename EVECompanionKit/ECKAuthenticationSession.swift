//
//  ECKAuthenticationSession.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.05.24.
//

import Foundation
import CryptoKit

public struct ECKAuthenticationSession {
    
    public static func start(authenticationHandler: (URL, String) async throws -> URL) async throws {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            NotificationCenter.default.post(name: .charactersDidChange, object: nil)
            return
        }
        
        var codeVerifierData = Data(count: 32)
        let randomizationResult = codeVerifierData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        guard randomizationResult == errSecSuccess else {
            logger.error("Randomization error")
            throw ECKAPIError.generic
        }
        
        let codeVerifier = codeVerifierData.base64URLEncodedString
        let codeVerifierHash = SHA256.hash(data: codeVerifier.data(using: .ascii)!)
        let codeVerifierHashString = Data(codeVerifierHash).base64URLEncodedString
        
        let state: String = UUID().uuidString
        
        var signInURLComponents = URLComponents(string: "https://login.eveonline.com/v2/oauth/authorize/")!
        var signInURLQueryItems = [URLQueryItem]()
        
        signInURLQueryItems.append(.init(name: "response_type", value: "code"))
        signInURLQueryItems.append(.init(name: "redirect_uri", value: ECKConstants.redirectURI))
        signInURLQueryItems.append(.init(name: "client_id", value: ECKConstants.clientId))
        signInURLQueryItems.append(.init(name: "scope", value: ECKAPIScope.allScopesString))
        signInURLQueryItems.append(.init(name: "code_challenge_method", value: "S256"))
        signInURLQueryItems.append(.init(name: "state", value: state))
        signInURLQueryItems.append(.init(name: "code_challenge", value: codeVerifierHashString))
        
        signInURLComponents.queryItems = signInURLQueryItems
        
        let urlWithToken = try await authenticationHandler(signInURLComponents.url!, ECKConstants.urlScheme)
        
        let urlComponents = URLComponents(url: urlWithToken, resolvingAgainstBaseURL: true)
        
        guard let receivedState = urlComponents?.queryItems?.first(where: { $0.name == "state" })?.value,
              state == receivedState else {
            throw ECKAPIError.stateMismatch
        }
        
        guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw ECKAPIError.codeNotSet
        }
        
        let tokenResult = try await ECKWebService().loadResource(resource: ECKCreateTokenResource(clientId: ECKConstants.clientId,
                                                                                                  codeVerifier: codeVerifier,
                                                                                                  code: code))
        
        await ECKKeychain.add(token: tokenResult.response)
    }
    
}
