//
//  ECKHomeLocation.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import Foundation

public class ECKHomeLocation: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case location = "location_id"
    }
    
    public let location: ECKStation?
    
    static let dummy: ECKHomeLocation = .init(location: .init(stationId: 60003760,
                                                              token: .dummy))
    
    init(location: ECKStation?) {
        self.location = location
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.location = try container.decodeIfPresent(ECKStation.self, forKey: .location)
    }
    
}
