//
//  ECKStructureResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.05.24.
//

import Foundation

class ECKStructureResource: ECKWebResource<ECKStructureResource.StructureResponse> {
    
    struct StructureResponse: Decodable {
        enum CodingKeys: String, CodingKey {
            case name
            case ownerId = "owner_id"
            case solarSystemId = "solar_system_id"
            case typeId = "type_id"
        }
        
        let name: String
        let ownerId: Int
        let solarSystemId: Int
        let typeId: Int?
    }
    
    init(structureId: Int, token: ECKToken) {
        super.init(host: .esi,
                   endpoint: "/v2/universe/structures/\(structureId)/",
                   token: token,
                   requiredScope: .readStructures)
    }
    
}
