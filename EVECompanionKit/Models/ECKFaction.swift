//
//  ECKFaction.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public class ECKFaction: Decodable, Equatable {
    
    public let factionId: Int
    public let name: String
    public let description: String
    public let iconId: Int?
    
    static let dummy: ECKFaction = .init(factionId: 500001)
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let factionId = try container.decode(Int.self)
        self.init(factionId: factionId)
    }
    
    convenience init(factionId: Int) {
        let data = ECKSDEManager.shared.getFaction(factionId: factionId)
        self.init(factionId: factionId, factionData: data)
    }
    
    init(factionId: Int, factionData: ECKSDEManager.FetchedFaction) {
        self.factionId = factionId
        self.name = factionData.name
        self.description = factionData.description
        self.iconId = factionData.iconId
    }
    
    public static func == (lhs: ECKFaction, rhs: ECKFaction) -> Bool {
        return lhs.factionId == rhs.factionId
        && lhs.name == rhs.name
        && lhs.description == rhs.description
        && lhs.iconId == rhs.iconId
    }
    
}
