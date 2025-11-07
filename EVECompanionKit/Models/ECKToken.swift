//
//  ECKToken.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation
import JWTDecode

internal final class ECKToken: Hashable, Equatable, Codable, Identifiable {
    
    static func == (lhs: ECKToken, rhs: ECKToken) -> Bool {
        return lhs.accessToken == rhs.accessToken &&
        lhs.refreshToken == rhs.refreshToken &&
        lhs.characterId == rhs.characterId &&
        lhs.characterName == rhs.characterName
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case isValid
    }
    
    private(set) internal var accessToken: String
    private(set) internal var refreshToken: String
    private(set) internal var characterId: Int
    private(set) internal var characterName: String
    private(set) internal var isValid: Bool
    private(set) internal var accessTokenExpiredFlag: Bool = false
    
    @MainActor
    internal var refreshTask: Task<Void, any Error>?
    
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
    
    lazy var id: String = {
        do {
            let jwt = try JWTDecode.decode(jwt: accessToken)
            guard let subject = jwt.subject else {
                logger.error("\(jwt) has no subject.")
                return UUID().uuidString
            }
            
            return subject
        } catch {
            logger.error("Error decoding jwt \(error)")
            return UUID().uuidString
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
    
    @MainActor
    internal func updateToken(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiredFlag = false
        ECKKeychain.update(token: self)
    }
    
    @MainActor
    internal func markAsInvalid() {
        self.isValid = false
        self.accessTokenExpiredFlag = true
        ECKKeychain.add(token: self)
    }
    
    @MainActor
    internal func markAccessTokenExpired() {
        self.accessTokenExpiredFlag = true
        ECKKeychain.add(token: self)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(refreshToken)
        hasher.combine(characterId)
        hasher.combine(characterName)
    }
    
}
