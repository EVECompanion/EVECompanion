//
//  ECKMapSystemDetails.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 27.06.26.
//

import Foundation

public struct ECKMapSystemDetails: Equatable, Identifiable, Sendable {

    public let id: Int
    public let name: String
    public let security: String
    public let regionName: String
    public let constellationName: String
    public let sovereigntyName: String?
    public let characters: [ECKCharacter]

    public init(id: Int,
                name: String,
                security: Double,
                regionName: String,
                constellationName: String,
                sovereigntyName: String?,
                characters: [ECKCharacter]) {
        self.id = id
        self.name = name
        self.security = ECFormatters.securityStatus(Float(security))
        self.regionName = regionName
        self.constellationName = constellationName
        self.sovereigntyName = sovereigntyName
        self.characters = characters.sorted(using: KeyPathComparator(\.name))
    }

    public init(system: ECKSolarSystem,
                constellationName: String,
                characters: [ECKCharacter]) {
        self.init(
            id: system.id,
            name: system.solarSystemName,
            security: system.security,
            regionName: system.region.name,
            constellationName: constellationName,
            sovereigntyName: system.sovereignty?.displayName,
            characters: characters
        )
    }

}
