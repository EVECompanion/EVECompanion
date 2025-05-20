//
//  ECKPlanetType.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.10.24.
//

import Foundation

public enum ECKPlanetType: String, Codable, Hashable {
    case temperate
    case barren
    case oceanic
    case ice
    case gas
    case lava
    case storm
    case plasma
    
    case unknown
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        guard let value = ECKPlanetType(rawValue: stringValue) else {
            logger.warning("Unknown ECKPlanetType \(stringValue)")
            self = .unknown
            return
        }
        
        self = value
    }
}
