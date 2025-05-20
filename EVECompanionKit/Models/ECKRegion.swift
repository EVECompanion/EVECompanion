//
//  ECKRegion.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public final class ECKRegion: Decodable, Hashable, Sendable {
    
    public let regionId: Int
    public let name: String
    
    static let dummy: ECKRegion = .init(regionId: 10000002)
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let regionId = try container.decode(Int.self)
        self.init(regionId: regionId)
    }
    
    convenience init(regionId: Int) {
        let regionName = ECKSDEManager.shared.getRegionName(regionId: regionId)
        self.init(regionId: regionId, regionName: regionName)
    }
    
    init(regionId: Int, regionName: String) {
        self.regionId = regionId
        self.name = regionName
    }
    
    public static func == (lhs: ECKRegion, rhs: ECKRegion) -> Bool {
        return lhs.regionId == rhs.regionId && lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(regionId)
        hasher.combine(name)
    }
    
}
