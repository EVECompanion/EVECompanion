//
//  ECKKeychain.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation
import Security

@ECKTokenActor
internal struct ECKKeychain {
    
    internal struct FailableDecodable<Base: Decodable>: Decodable {

        let base: Base?

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                self.base = try container.decode(Base.self)
            } catch {
                logger.error("Error decoding data to \(Base.self): \(error)")
                self.base = nil
            }
        }
    }
    
    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()
    private static let legacyTokenKey = "tokens"
    private static let legacyTokenAccount = ECKAppInfo.bundleId + legacyTokenKey
    private static let tokenService = "\(ECKAppInfo.bundleId).tokens"
    
    private static let tokenLock = NSLock()
    
    @ECKTokenActor
    static func add(token: ECKToken) {
        tokenLock.lock()
        defer {
            tokenLock.unlock()
        }

        guard token.isRemoved == false else {
            logger.info("Skipping add for removed token \(storageAccount(for: token))")
            return
        }
        
        var currentTokens = getTokens()
        var isNewToken: Bool = false
        let tokenStorageAccount = storageAccount(for: token)
        logger.info("Adding token \(tokenStorageAccount)")
        
        if let existingToken = currentTokens.enumerated().first(where: { storageAccount(for: $0.element) == tokenStorageAccount }) {
            logger.info("Token \(tokenStorageAccount) is replacing an existing token.")
            let resolvedToken = preferredToken(between: existingToken.element, and: token)
            currentTokens[existingToken.offset] = resolvedToken
            isNewToken = existingToken.element.isValid == false && resolvedToken.isValid
        } else {
            logger.info("Token \(tokenStorageAccount) is a new token.")
            isNewToken = true
            currentTokens.append(token)
        }
        
        set(tokens: currentTokens)
        if isNewToken {
            logger.debug("Detected new token, refreshing app.")
            NotificationCenter.default.post(name: .tokensDidChange, object: nil)
        }
    }
    
    @ECKTokenActor
    static func remove(token: ECKToken) {
        token.prepareForRemoval()

        for account in knownAccounts(for: token) {
            let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                logger.error("Could not delete token \(account). Status: \(status)")
            }
        }
        
        NotificationCenter.default.post(name: .tokensDidChange, object: nil)
    }
    
    @ECKTokenActor
    private static func set(tokens: [ECKToken]) {
        let sortedTokens = tokens.sorted { lhsToken, rhsToken in
            return lhsToken.characterName < rhsToken.characterName
        }
        
        logger.info("Saving tokens \(sortedTokens)")
        
        for token in sortedTokens {
            set(token: token)
        }
    }
    
    @ECKTokenActor
    static func getTokens(target: ECKAuthenticationTarget) -> [ECKToken] {
        let allTokens = getTokens()
        return allTokens.filter({ $0.tokenTarget == target })
    }

    @ECKTokenActor
    private static func getTokens() -> [ECKToken] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return migrateLegacyTokensIfNeeded()
        }

        guard status == errSecSuccess else {
            logger.error("Could not load tokens. Status: \(status)")
            return []
        }

        let itemEntries: [[String: Any]]
        if let entry = item as? [String: Any] {
            itemEntries = [entry]
        } else if let entries = item as? [[String: Any]] {
            itemEntries = entries
        } else {
            logger.error("Unexpected keychain payload while loading tokens: \(String(describing: item))")
            return []
        }
        
        var tokensByStorageAccount: [String: (token: ECKToken, account: String)] = [:]
        var obsoleteAccounts = Set<String>()
        
        for entry in itemEntries {
            guard let tokenData = entry[kSecValueData as String] as? Data,
                  let token = decodeToken(from: tokenData) else {
                continue
            }
            
            let expectedAccount = storageAccount(for: token)
            let actualAccount = entry[kSecAttrAccount as String] as? String ?? expectedAccount
            
            if let existingEntry = tokensByStorageAccount[expectedAccount] {
                if existingEntry.account != expectedAccount && actualAccount == expectedAccount {
                    obsoleteAccounts.insert(existingEntry.account)
                    tokensByStorageAccount[expectedAccount] = (token: token, account: actualAccount)
                } else {
                    obsoleteAccounts.insert(actualAccount)
                }
            } else {
                tokensByStorageAccount[expectedAccount] = (token: token, account: actualAccount)
            }
            
            if actualAccount != expectedAccount {
                obsoleteAccounts.insert(actualAccount)
            }
        }
        
        persistCanonicalTokensIfNeeded(from: tokensByStorageAccount)
        removeObsoleteAccounts(obsoleteAccounts)
        
        let tokens = tokensByStorageAccount.values.map(\.token)
        logger.info("Decoded tokens \(tokens)")
        return tokens.sorted(by: { $0.characterName < $1.characterName })
    }
    
    @ECKTokenActor
    private static func set(token: ECKToken) {
        do {
            let data = try jsonEncoder.encode(token)
            let tokenStorageAccount = storageAccount(for: token)
            let query = baseQuery(account: tokenStorageAccount)
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus == errSecItemNotFound {
                var addQuery = query
                addQuery[kSecValueData as String] = data
                addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
                let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                if addStatus != errSecSuccess {
                    logger.error("Could not add token \(tokenStorageAccount). Status: \(addStatus)")
                }
            } else if updateStatus != errSecSuccess {
                logger.error("Could not update token \(tokenStorageAccount). Status: \(updateStatus)")
            }
            
            removeObsoleteAccounts(Set(knownAccounts(for: token).filter { $0 != tokenStorageAccount }))
        } catch {
            logger.error("Cannot encode token \(storageAccount(for: token)): \(error)")
        }
    }
    
    @ECKTokenActor
    private static func migrateLegacyTokensIfNeeded() -> [ECKToken] {
        guard let legacyItem = loadLegacyTokenData() else {
            logger.warning("Keychain has no tokens for key \(legacyTokenKey) in known legacy locations")
            return []
        }
        
        do {
            let tokens = try jsonDecoder.decode([FailableDecodable<ECKToken>].self, from: legacyItem.data)
                .compactMap(\.base)
            logger.info("Migrating legacy tokens \(tokens)")
            set(tokens: tokens)
            let deleteStatus = SecItemDelete(legacyDeleteQuery() as CFDictionary)
            if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
                logger.error("Could not delete legacy token array. Status: \(deleteStatus)")
            }
            return tokens
        } catch {
            logger.error("Error decoding legacy tokens: \(error)")
            return []
        }
    }

    private static func loadLegacyTokenData() -> (query: [String: Any], data: Data)? {
        let query = legacyQuery()
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            logger.info("Found legacy token array using account \(legacyTokenAccount)")
            return (query: query, data: data)
        }
        
        return nil
    }

    private static func decodeToken(from tokenData: Data) -> ECKToken? {
        do {
            return try jsonDecoder.decode(FailableDecodable<ECKToken>.self, from: tokenData).base
        } catch {
            logger.error("Error decoding token payload: \(error)")
            return nil
        }
    }

    private static func baseQuery(account: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: account
        ]
    }

    private static func removeObsoleteAccounts(_ accounts: Set<String>) {
        for account in accounts {
            let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                logger.error("Could not delete obsolete token account \(account). Status: \(status)")
            }
        }
    }

    @ECKTokenActor
    private static func persistCanonicalTokensIfNeeded(from entries: [String: (token: ECKToken, account: String)]) {
        for (expectedAccount, entry) in entries where entry.account != expectedAccount {
            set(token: entry.token)
        }
    }

    private static func legacyQuery() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: legacyTokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
    }

    private static func legacyDeleteQuery() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: legacyTokenAccount
        ]
    }

    private static func storageAccount(for token: ECKToken) -> String {
        return "\(token.characterId)-\(token.tokenTarget.rawValue)"
    }

    private static func knownAccounts(for token: ECKToken) -> [String] {
        return Array(Set([
            storageAccount(for: token),
            token.id
        ]))
    }

    private static func preferredToken(between existingToken: ECKToken, and incomingToken: ECKToken) -> ECKToken {
        if incomingToken.refreshToken == existingToken.refreshToken {
            return incomingToken
        }

        if incomingToken.isValid != existingToken.isValid {
            return incomingToken.isValid ? incomingToken : existingToken
        }

        let existingExpiry = existingToken.accessTokenExpirationDate ?? .distantPast
        let incomingExpiry = incomingToken.accessTokenExpirationDate ?? .distantPast

        if incomingExpiry >= existingExpiry {
            return incomingToken
        } else {
            return existingToken
        }
    }
    
}
