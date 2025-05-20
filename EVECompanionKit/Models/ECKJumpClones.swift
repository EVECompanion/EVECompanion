//
//  ECKJumpClones.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import Foundation

public class ECKJumpClones: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case homeLocation = "home_location"
        case jumpClones = "jump_clones"
        case lastJumpCloneDate = "last_clone_jump_date"
        case lastStationChangeDate = "last_station_change_date"
    }
    
    public let homeLocation: ECKHomeLocation
    public let jumpClones: [ECKJumpClone]
    public let lastJumpCloneDate: Date?
    public let lastStationChangeDate: Date?
    
    public static let dummy: ECKJumpClones = .init(homeLocation: .dummy,
                                                   jumpClones: [.dummy],
                                                   lastJumpCloneDate: Date() - .fromHours(hours: 5),
                                                   lastStationChangeDate: Date() - .fromDays(days: 1))
    
    init(homeLocation: ECKHomeLocation, 
         jumpClones: [ECKJumpClone],
         lastJumpCloneDate: Date?,
         lastStationChangeDate: Date?) {
        self.homeLocation = homeLocation
        self.jumpClones = jumpClones
        self.lastJumpCloneDate = lastJumpCloneDate
        self.lastStationChangeDate = lastStationChangeDate
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.homeLocation = try container.decode(ECKHomeLocation.self, forKey: .homeLocation)
        self.jumpClones = try container.decode([ECKJumpClone].self, forKey: .jumpClones)
        self.lastJumpCloneDate = try container.decodeIfPresent(Date.self, forKey: .lastJumpCloneDate)
        self.lastStationChangeDate = try container.decodeIfPresent(Date.self, forKey: .lastStationChangeDate)
    }
    
}
