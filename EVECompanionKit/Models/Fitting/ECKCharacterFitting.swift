//
//  ECKCharacterFitting.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

public class ECKCharacterFitting: Decodable, Identifiable, Hashable, ObservableObject {
    
    internal typealias AttributeID = Int
    
    static let attributeMassId: Int = 4
    static let attributeCapacityId: Int = 38
    static let attributeVolumeId: Int = 161
    static let attributeRadiusId: Int = 162
    static let attributeSkillLevelId: Int = 280
    
    private enum CodingKeys: String, CodingKey {
        case description
        case fittingId = "fitting_id"
        case items
        case name
        case ship = "ship_type_id"
    }
    
    public var id: Int {
        return fittingId
    }
    
    public let description: String
    public let fittingId: Int
    public var items: [ECKCharacterFittingItem]
    public let name: String
    public let ship: ECKItem
    
    public static let dummyAvatar: ECKCharacterFitting = {
        return .init(description: "Just my avatar",
                     fittingId: 0,
                     items: [],
                     name: "EVECompanion's Avatar",
                     ship: .init(typeId: 11567))
    }()
    
    internal var attributes: [AttributeID: ECKFittingAttribute] = [:]
    internal var skills: [ECKCharacterSkills] = []
    
    init(description: String,
         fittingId: Int,
         items: [ECKCharacterFittingItem],
         name: String,
         ship: ECKItem) {
        self.description = description
        self.fittingId = fittingId
        self.items = items
        self.name = name
        self.ship = ship
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.fittingId = try container.decode(Int.self, forKey: .fittingId)
        self.items = try container.decode([ECKCharacterFittingItem].self, forKey: .items)
        self.name = try container.decode(String.self, forKey: .name)
        self.ship = try container.decode(ECKItem.self, forKey: .ship)
    }
    
    public static func == (lhs: ECKCharacterFitting, rhs: ECKCharacterFitting) -> Bool {
        return lhs.description == rhs.description
        && lhs.fittingId == rhs.fittingId
        && lhs.items == rhs.items
        && lhs.name == rhs.name
        && lhs.ship == rhs.ship
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(fittingId)
        hasher.combine(items)
        hasher.combine(name)
        hasher.combine(ship)
    }
    
}
