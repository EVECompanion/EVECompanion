//
//  ECKCharacterOnline.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.26.
//

import Foundation

public final class ECKCharacterOnline: Decodable, Sendable {

    private enum CodingKeys: String, CodingKey {
        case lastLogin = "last_login"
        case lastLogout = "last_logout"
        case logins
        case online
    }

    public let lastLogin: Date?
    public let lastLogout: Date?
    public let logins: Int?
    public let online: Bool

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lastLogin = try container.decodeIfPresent(Date.self, forKey: .lastLogin)
        self.lastLogout = try container.decodeIfPresent(Date.self, forKey: .lastLogout)
        self.logins = try container.decodeIfPresent(Int.self, forKey: .logins)
        self.online = try container.decode(Bool.self, forKey: .online)
    }

}
