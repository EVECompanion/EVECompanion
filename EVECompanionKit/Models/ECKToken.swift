//
//  ECKToken.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation
import JWTDecode

@globalActor
internal actor ECKTokenActor {
    static let shared = ECKTokenActor()

    @ECKTokenActor
    private static var ongoingRefreshTasks: [String: (id: UUID, task: Task<Void, any Error>)] = [:]

    private init() { }

    @ECKTokenActor
    static func refreshTask(for account: String) -> Task<Void, any Error>? {
        return ongoingRefreshTasks[account]?.task
    }

    @ECKTokenActor
    static func registerRefreshTask(_ task: Task<Void, any Error>, for account: String, id: UUID) -> Task<Void, any Error>? {
        guard ongoingRefreshTasks[account] == nil else {
            return ongoingRefreshTasks[account]?.task
        }
        ongoingRefreshTasks[account] = (id: id, task: task)
        return nil
    }

    @ECKTokenActor
    static func clearRefreshTask(for account: String, matching id: UUID) {
        guard ongoingRefreshTasks[account]?.id == id else { return }
        ongoingRefreshTasks[account] = nil
    }
}

internal final class ECKToken: Hashable, Equatable, Codable, Identifiable, @unchecked Sendable {

    internal enum RefreshUpdateResult: Equatable {
        case updated
        case superseded
        case missing
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case isValid
        case tokenTarget
    }
    
    private(set) internal var accessToken: String
    private(set) internal var refreshToken: String
    private(set) internal var characterId: Int
    private(set) internal var characterName: String
    private(set) internal var isValid: Bool
    private(set) internal var accessTokenExpiredFlag: Bool = false
    @ECKTokenActor
    private(set) internal var isRemoved: Bool = false
    internal var tokenTarget: ECKAuthenticationTarget = .character
    
    internal var storageAccount: String {
        return "\(characterId)-\(tokenTarget.rawValue)"
    }

    static let dummy: ECKToken = .init()
    
    @MainActor
    internal var isExpired: Bool {
        guard accessTokenExpiredFlag == false else {
            return true
        }
        
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            return jwt.expired
        } catch {
            logger.error("Error decoding jwt \(error)")
            return true
        }
    }

    internal var accessTokenExpirationDate: Date? {
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            return jwt.expiresAt
        } catch {
            logger.error("Error decoding jwt \(error)")
            return nil
        }
    }
    
    private var scopes: [String] {
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            guard let scopes = jwt.body["scp"] as? [String] else {
                logger.error("\(jwt) has no scopes.")
                return []
            }
            
            return scopes
        } catch {
            logger.error("Error decoding jwt \(error)")
            return []
        }
    }
    
    lazy var id: String = {
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            guard let subject = jwt.subject else {
                logger.error("\(jwt) has no subject.")
                return UUID().uuidString + "-\(tokenTarget.rawValue)"
            }
            
            return subject + "-\(tokenTarget.rawValue)"
        } catch {
            logger.error("Error decoding jwt \(error)")
            return UUID().uuidString + "-\(tokenTarget.rawValue)"
        }
    }()
    
    private init() {
        self.accessToken = ""
        self.refreshToken = ""
        self.characterId = 2123087197
        self.characterName = "EVECompanion"
        self.isValid = true
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decode(String.self, forKey: .refreshToken)
        self.isValid = try container.decodeIfPresent(Bool.self, forKey: .isValid) ?? true
        self.tokenTarget = try container.decodeIfPresent(ECKAuthenticationTarget.self, forKey: .tokenTarget) ?? .character
        
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            let characterIdString = (jwt.subject ?? "").replacingOccurrences(of: "CHARACTER:EVE:", with: "")
            guard let characterId = Int(characterIdString) else {
                throw ECKAPIError.characterIdUnknown
            }
            self.characterId = characterId
            self.characterName = (jwt.body["name"] as? String) ?? ""
        } catch {
            logger.error("Error decoding jwt \(error)")
            throw ECKAPIError.characterIdUnknown
        }
    }
    
    @ECKTokenActor
    internal func updateToken(
        accessToken: String,
        refreshToken: String,
        replacingAccessToken expectedAccessToken: String,
        refreshToken expectedRefreshToken: String
    ) -> RefreshUpdateResult {
        guard isRemoved == false else {
            logger.info("Skipping token update for removed token \(characterId)-\(tokenTarget.rawValue)")
            return .missing
        }

        guard let storedToken = ECKKeychain.getTokens(target: tokenTarget).first(where: { $0.characterId == characterId }) else {
            logger.info("Skipping token update because stored token is missing for \(characterId)-\(tokenTarget.rawValue)")
            return .missing
        }

        guard storedToken.accessToken == expectedAccessToken,
              storedToken.refreshToken == expectedRefreshToken else {
            logger.info("Skipping stale token update for \(characterId)-\(tokenTarget.rawValue); syncing from keychain")
            sync(from: storedToken)
            return .superseded
        }

        let wasValid = self.isValid
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isValid = true
        self.accessTokenExpiredFlag = false
        guard ECKKeychain.replace(
            token: self,
            replacingAccessToken: expectedAccessToken,
            refreshToken: expectedRefreshToken
        ) else {
            if let latestToken = ECKKeychain.getTokens(target: tokenTarget).first(where: { $0.characterId == characterId }) {
                if latestToken.accessToken != expectedAccessToken || latestToken.refreshToken != expectedRefreshToken {
                    sync(from: latestToken)
                    return .superseded
                }

                self.isValid = latestToken.isValid
            } else {
                self.isValid = wasValid
            }

            self.accessToken = expectedAccessToken
            self.refreshToken = expectedRefreshToken
            self.accessTokenExpiredFlag = true
            return .missing
        }
        return .updated
    }

    @ECKTokenActor
    internal func sync(from otherToken: ECKToken) {
        guard isRemoved == false else { return }
        self.accessToken = otherToken.accessToken
        self.refreshToken = otherToken.refreshToken
        self.isValid = otherToken.isValid
        self.accessTokenExpiredFlag = otherToken.accessTokenExpiredFlag
    }
    
    @ECKTokenActor
    internal func markAsInvalid() {
        _ = markAsInvalid(expectedAccessToken: accessToken, expectedRefreshToken: refreshToken)
    }

    @ECKTokenActor
    internal func markAsInvalid(expectedAccessToken: String, expectedRefreshToken: String) -> Bool {
        guard isRemoved == false else {
            logger.info("Skipping token invalidation for removed token \(characterId)-\(tokenTarget.rawValue)")
            return false
        }

        guard let storedToken = ECKKeychain.getTokens(target: tokenTarget).first(where: { $0.characterId == characterId }) else {
            logger.info("Skipping token invalidation because stored token is missing for \(characterId)-\(tokenTarget.rawValue)")
            return false
        }

        guard accessToken == expectedAccessToken,
              refreshToken == expectedRefreshToken,
              storedToken.accessToken == expectedAccessToken,
              storedToken.refreshToken == expectedRefreshToken else {
            logger.info("Skipping stale token invalidation for \(characterId)-\(tokenTarget.rawValue); syncing from keychain")
            sync(from: storedToken)
            return false
        }

        self.isValid = false
        self.accessTokenExpiredFlag = true
        ECKKeychain.add(token: self)
        return true
    }
    
    @ECKTokenActor
    internal func markAccessTokenExpired() {
        guard isRemoved == false else {
            logger.info("Skipping token expiry mark for removed token \(characterId)-\(tokenTarget.rawValue)")
            return
        }

        self.accessTokenExpiredFlag = true
    }

    @ECKTokenActor
    internal func prepareForRemoval() {
        isRemoved = true
        let account = storageAccount
        if let task = ECKTokenActor.refreshTask(for: account) {
            task.cancel()
            // Keep the account registered until the task's defer clears it.
            // Cancellation does not end the URLSession continuation immediately.
        }
    }
    
    @MainActor
    internal func includesScope(scope: ECKAPIScope) -> Bool {
        return scopes.contains(scope.rawValue)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(refreshToken)
        hasher.combine(characterId)
        hasher.combine(characterName)
        hasher.combine(tokenTarget)
    }
    
    static func == (lhs: ECKToken, rhs: ECKToken) -> Bool {
        return lhs.accessToken == rhs.accessToken &&
        lhs.refreshToken == rhs.refreshToken &&
        lhs.characterId == rhs.characterId &&
        lhs.characterName == rhs.characterName &&
        lhs.tokenTarget == rhs.tokenTarget
    }
    
}
