//
//  ECKCharacterLocation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 20.10.25.
//

import Foundation

public class ECKCharacterLocation: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case solarSystem = "solar_system_id"
        case stationId = "station_id"
        case structureId = "structure_id"
    }
    
    public let solarSystem: ECKSolarSystem
    public var station: ECKStation?
    
    static let dummyDocked: ECKCharacterLocation = {
        return .init(solarSystem: .jita,
                     station: .jita)
    }()
    
    static let dummyUndocked: ECKCharacterLocation = {
        return .init(solarSystem: .jita, station: nil)
    }()
    
    init(solarSystem: ECKSolarSystem, station: ECKStation?) {
        self.solarSystem = solarSystem
        self.station = station
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.solarSystem = try container.decode(ECKSolarSystem.self, forKey: .solarSystem)
        
        // swiftlint:disable:next force_cast
        let token = decoder.userInfo[ECKWebService.tokenCodingUserInfoKey] as! ECKToken
        if let stationId = try container.decodeIfPresent(Int.self, forKey: .stationId) {
            self.station = .init(stationId: stationId, token: token)
        } else if let structureId = try container.decodeIfPresent(Int.self, forKey: .structureId) {
            self.station = .init(stationId: structureId, token: token)
        } else {
            self.station = nil
        }
    }
    
}
