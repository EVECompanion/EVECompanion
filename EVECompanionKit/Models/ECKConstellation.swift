//
//  ECKConstellation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public class ECKConstellation: Decodable {
    
    public let constellationId: Int
    public let name: String
    
    @MainActor
    static let dummy: ECKConstellation = .init(constellationId: 10000002)
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let constellationId = try container.decode(Int.self)
        self.init(constellationId: constellationId)
    }
    
    convenience init(constellationId: Int) {
        let constellationName = ECKSDEManager.shared.getConstellationName(constellationId: constellationId)
        self.init(constellationId: constellationId, constellationName: constellationName)
    }
    
    init(constellationId: Int, constellationName: String) {
        self.constellationId = constellationId
        self.name = constellationName
    }
    
}
