//
//  ECKConstellation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public final class ECKConstellation: Decodable, Sendable {
    
    public let constellationId: Int
    public let region: ECKRegion
    public let name: String
    
    @MainActor
    static let dummy: ECKConstellation = .init(constellationId: 10000002)
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let constellationId = try container.decode(Int.self)
        self.init(constellationId: constellationId)
    }
    
    convenience init(constellationId: Int) {
        let constellationData = ECKSDEManager.shared.getConstellation(constellationId: constellationId)
        self.init(
            constellationId: constellationData.constellationId,
            constellationName: constellationData.constellationName,
            regionId: constellationData.regionId
        )
    }
    
    init(constellationId: Int, constellationName: String, regionId: Int) {
        self.constellationId = constellationId
        self.region = .init(regionId: regionId)
        self.name = constellationName
    }
    
    convenience init(fetchedConstellation: ECKSDEManager.FetchedConstellation) {
        self.init(
            constellationId: fetchedConstellation.constellationId,
            constellationName: fetchedConstellation.constellationName,
            regionId: fetchedConstellation.regionId
        )
    }
    
}
