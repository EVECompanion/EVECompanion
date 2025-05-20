//
//  ECKJumpClone.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import Foundation

public class ECKJumpClone: Decodable, ObservableObject, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case implants
        case jumpCloneId = "jump_clone_id"
        case location = "location_id"
        case name
    }
    
    public var id: Int {
        return jumpCloneId
    }
    
    public let implants: [ECKItem]
    let jumpCloneId: Int
    @NestedObservableObject public var location: ECKStation
    public let name: String?
    
    public static let dummy: ECKJumpClone = .init(implants: [
        .init(typeId: 16246),
        .init(typeId: 16248),
        .init(typeId: 27116),
        .init(typeId: 53710),
        .init(typeId: 53711),
        .init(typeId: 53712),
        .init(typeId: 53713),
        .init(typeId: 53714),
        .init(typeId: 53715),
        .init(typeId: 54544)
    ],
                                                  jumpCloneId: 0,
                                                  location: .init(stationId: 60003760,
                                                                  token: .dummy),
                                                  name: "Jump Clone")
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.implants = try container.decode([ECKItem].self, forKey: .implants)
        self.jumpCloneId = try container.decode(Int.self, forKey: .jumpCloneId)
        self.location = try container.decode(ECKStation.self, forKey: .location)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    init(implants: [ECKItem],
         jumpCloneId: Int,
         location: ECKStation,
         name: String?) {
        self.implants = implants
        self.jumpCloneId = jumpCloneId
        self.location = location
        self.name = name
    }
    
}
