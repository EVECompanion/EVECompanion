//
//  ECKAssetLocation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

public enum ECKAssetLocation: Decodable, Hashable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case locationType = "location_type"
    }
    
    case station(ECKStation)
    case solarSystem(ECKSolarSystem)
    case item(itemId: Int)
    case other(id: Int)
    case unknown
    
    public var id: String {
        switch self {
        case .station(let station):
            return "station.\(station.stationId)"
        case .solarSystem(let solarSystem):
            return "solarSystem.\(solarSystem.solarSystemId)"
        case .item(let itemId):
            return "item.\(itemId)"
        case .other(let id):
            return "other.\(id)"
        case .unknown:
            return "unknown"
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let locationId = try container.decode(Int.self, forKey: .locationId)
        let locationType = try container.decode(String.self, forKey: .locationType)
        
        switch locationType {
        case "station":
            // swiftlint:disable:next force_cast
            let token = decoder.userInfo[ECKWebService.tokenCodingUserInfoKey] as! ECKToken
            self = .station(.init(stationId: locationId, token: token))
            
        case "solar_system":
            self = .solarSystem(.init(solarSystemId: locationId))
            
        case "item":
            self = .item(itemId: locationId)
            
        case "other":
            self = .other(id: locationId)
            
        default:
            self = .unknown
            
        }
    }
    
    public static func == (lhs: ECKAssetLocation, rhs: ECKAssetLocation) -> Bool {
        switch (lhs, rhs) {
            
        case (.station(let lhsStation), .station(let rhsStation)):
            return lhsStation.stationId == rhsStation.stationId
            
        case (.solarSystem(let lhsSolarSystem), .solarSystem(let rhsSolarSystem)):
            return lhsSolarSystem.solarSystemId == rhsSolarSystem.solarSystemId
            
        case (.item(let lhsItemId), .item(let rhsItemId)):
            return lhsItemId == rhsItemId
            
        case (.other(let lhsId), .other(let rhsId)):
            return lhsId == rhsId
            
        case (.unknown, .unknown):
            return true
            
        default:
            return false
            
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .station(let station):
            hasher.combine("station")
            hasher.combine(station.stationId)
            
        case .solarSystem(let solarSystem):
            hasher.combine("solarSystem")
            hasher.combine(solarSystem.solarSystemId)
            
        case .item(let itemId):
            hasher.combine("item")
            hasher.combine(itemId)
            
        case .other(let id):
            hasher.combine("other")
            hasher.combine(id)
            
        case .unknown:
            hasher.combine("unknown")
            
        }
    }
    
}
