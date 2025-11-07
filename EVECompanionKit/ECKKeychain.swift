//
//  ECKKeychain.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation
@preconcurrency import KeychainSwift

internal struct ECKKeychain {
    
    internal struct FailableDecodable<Base: Decodable>: Decodable {

        let base: Base?

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.base = try? container.decode(Base.self)
        }
    }
    
    static let keychain: KeychainSwift = {
        let keychain = KeychainSwift(keyPrefix: ECKAppInfo.bundleId)
        keychain.synchronizable = false
        return keychain
    }()
    
    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()
    private static let tokenKey = "tokens"
    
    @MainActor
    static func add(token: ECKToken) {
        var currentTokens = getTokens()
        var isNewToken: Bool = false
        logger.info("Adding token \(token.id)")
        
        if let existingToken = currentTokens.enumerated().first(where: { $0.element.id == token.id }) {
            logger.info("Token \(token.id) is replacing an existing token.")
            currentTokens[existingToken.offset] = token
            isNewToken = existingToken.element.isValid == false && token.isValid
        } else {
            logger.info("Token \(token.id) is a new token.")
            isNewToken = true
            currentTokens.append(token)
        }
        
        set(tokens: currentTokens)
        if isNewToken {
            logger.debug("Detected new token, refreshing app.")
            NotificationCenter.default.post(name: .charactersDidChange, object: nil)
        }
    }
    
    @MainActor
    static func update(token: ECKToken) {
        add(token: token)
    }
    
    @MainActor
    static func remove(token: ECKToken) {
        let currentTokens = getTokens()
        let updatedTokens = currentTokens.filter({ $0.id != token.id })
        set(tokens: updatedTokens)
        
        NotificationCenter.default.post(name: .charactersDidChange, object: nil)
    }
    
    @MainActor
    private static func set(tokens: [ECKToken]) {
        let sortedTokens = tokens.sorted { lhsToken, rhsToken in
            return lhsToken.characterName < rhsToken.characterName
        }
        
        logger.info("Saving tokens \(sortedTokens)")
        
        do {
            let data = try jsonEncoder.encode(sortedTokens)
            keychain.set(data, forKey: tokenKey)
        } catch {
            logger.error("Cannot encode tokens \(tokens): \(error)")
        }
    }
    
    @MainActor
    static func getTokens() -> [ECKToken] {
        guard let tokenData = keychain.getData(tokenKey) else {
            logger.warning("Keychain has no tokens for key \(tokenKey)")
            return []
        }
        
        do {
            let tokens = try jsonDecoder.decode([FailableDecodable<ECKToken>].self, from: tokenData)
            logger.info("Decoded tokens \(tokens)")
            return tokens.compactMap({ $0.base })
        } catch {
            logger.error("Error decoding tokens: \(error)")
            return []
        }
    }
    
}
