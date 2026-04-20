//
//  ECKCorporationRoles.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.04.26.
//

import Foundation

public struct ECKCorporationRoles: Decodable, Sendable {
    
    private enum CodingKeys: String, CodingKey {
        case roles
        case rolesAtBase = "roles_at_base"
        case rolesAtHQ = "roles_at_hq"
        case rolesAtOther = "roles_at_other"
    }
    
    public let roles: [ECKCorporationRole]
    public let rolesAtBase: [ECKCorporationRole]
    public let rolesAtHQ: [ECKCorporationRole]
    public let rolesAtOther: [ECKCorporationRole]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.roles = try container.decodeIfPresent([ECKCorporationRole].self, forKey: .roles) ?? []
        self.rolesAtBase = try container.decodeIfPresent([ECKCorporationRole].self, forKey: .rolesAtBase) ?? []
        self.rolesAtHQ = try container.decodeIfPresent([ECKCorporationRole].self, forKey: .rolesAtHQ) ?? []
        self.rolesAtOther = try container.decodeIfPresent([ECKCorporationRole].self, forKey: .rolesAtOther) ?? []
    }
    
}
