//
//  ECKItem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import Foundation

public final class ECKItem: Codable, Identifiable, @unchecked Sendable, Hashable {
    
    public var id: Int {
        return typeId
    }
    
    public let typeId: Int
    public let name: String
    private let description: String?
    public lazy var attributedDescription: AttributedString? = {
        return description?.convertToAttributed()
    }()
    public let mass: Float?
    public let volume: Float?
    public let capacity: Float?
    public let radius: Float?
    public let iconId: Int?
    
    public var category: String {
        return itemCategory.category
    }
    
    public var group: String {
        return itemCategory.group
    }
    
    internal lazy var itemCategory: ECKSDEManager.ItemCategory = {
        return ECKSDEManager.shared.itemCategory(typeId)
    }()
    
    public private(set) lazy var itemTraits: ECKSDEManager.ItemTraits = {
        return ECKSDEManager.shared.itemTraits(typeId)
    }()
    
    public private(set) lazy var itemAttributeCategories: ECKSDEManager.ItemAttributes = {
        return ECKSDEManager.shared.itemAttributes(typeId)
    }()
    
    public struct SkillRequirement: Identifiable {
        public let skill: ECKItem
        public let requiredLevel: Int
        
        public let id = UUID()
        
        public lazy var children: [SkillRequirement]? = {
            return skill.skillRequirements
        }()
    }
    
    public private(set) lazy var skillRequirements: [SkillRequirement]? = {
        let requirements = ECKSDEManager.shared.requiredSkills(typeId: id)
        guard requirements.isEmpty == false else {
            return nil
        }
        return requirements.map({ .init(skill: .init(typeId: $0.skillId), requiredLevel: $0.requiredLevel) })
    }()
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let itemId = try container.decode(Int.self)
        self.init(typeId: itemId)
    }
    
    public convenience init(typeId: Int) {
        let itemData = ECKSDEManager.shared.getItem(typeId: typeId)
        self.init(itemData: itemData)
    }
    
    init(itemData: ECKSDEManager.FetchedItem) {
        self.typeId = itemData.typeId
        self.name = itemData.name
        self.description = itemData.description
        self.mass = itemData.mass
        self.volume = itemData.volume
        self.capacity = itemData.capacity
        self.radius = itemData.radius
        self.iconId = itemData.iconId
    }
    
    public static func == (lhs: ECKItem, rhs: ECKItem) -> Bool {
        return lhs.typeId == rhs.typeId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeId)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(typeId)
    }
    
}
