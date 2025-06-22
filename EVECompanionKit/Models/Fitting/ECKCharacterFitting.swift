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
    static let attributeStructureHPId: Int = 9
    static let attributeLowSlotsId: Int = 12
    static let attributeMidSlotsId: Int = 13
    static let attributeHighSlotsId: Int = 14
    static let attributeCapacityId: Int = 38
    static let attributeStructureKineticResistId: Int = 109
    static let attributeStructureThermalResistId: Int = 110
    static let attributeStructureExplosiveResistId: Int = 111
    static let attributeStructureEMResistId: Int = 113
    static let attributeShieldHPId: Int = 263
    static let attributeArmorHPId: Int = 265
    static let attributeArmorKineticResistId: Int = 269
    static let attributeArmorThermalResistId: Int = 270
    static let attributeArmorExplosiveResistId: Int = 268
    static let attributeArmorEMResistId: Int = 267
    static let attributeShieldEMResistId: Int = 271
    static let attributeShieldExplosiveResistId: Int = 272
    static let attributeShieldKineticResistId: Int = 273
    static let attributeShieldThermalResistId: Int = 274
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
    public let ship: ECKCharacterFittingItem
    
    public static let dummyAvatar: ECKCharacterFitting = {
        let fitting = ECKCharacterFitting(description: "Just my avatar",
                                          fittingId: 0,
                                          items: [],
                                          name: "EVECompanion's Avatar",
                                          ship: .init(typeId: 11567))
        fitting.calculateAttributes(skills: .dummy)
        return fitting
    }()
    
    public var resistances: Resistances? {
        let attributes = ship.attributes
        
        guard attributes.isEmpty == false else {
            return nil
        }
        
        let structure: ResistanceStats = .init(hp: attributes[Self.attributeStructureHPId]?.value ?? 0,
                                               em: attributes[Self.attributeStructureEMResistId]?.value ?? 0,
                                               explosive: attributes[Self.attributeStructureExplosiveResistId]?.value ?? 0,
                                               kinetic: attributes[Self.attributeStructureKineticResistId]?.value ?? 0,
                                               thermal: attributes[Self.attributeStructureThermalResistId]?.value ?? 0)
        
        let armor: ResistanceStats = .init(hp: attributes[Self.attributeArmorHPId]?.value ?? 0,
                                           em: attributes[Self.attributeArmorEMResistId]?.value ?? 0,
                                           explosive: attributes[Self.attributeArmorExplosiveResistId]?.value ?? 0,
                                           kinetic: attributes[Self.attributeArmorKineticResistId]?.value ?? 0,
                                           thermal: attributes[Self.attributeArmorThermalResistId]?.value ?? 0)
        
        let shield: ResistanceStats = .init(hp: attributes[Self.attributeShieldHPId]?.value ?? 0,
                                            em: attributes[Self.attributeShieldEMResistId]?.value ?? 0,
                                            explosive: attributes[Self.attributeShieldExplosiveResistId]?.value ?? 0,
                                            kinetic: attributes[Self.attributeShieldKineticResistId]?.value ?? 0,
                                            thermal: attributes[Self.attributeShieldThermalResistId]?.value ?? 0)
        
        return .init(structure: structure, armor: armor, shield: shield)
    }
    
    public var fittingAttributes: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: FittingAttribute)] {
        var fittingAttributes: [FittingAttribute] = Array(ship.attributes.values)
        fittingAttributes.sort(by: { $0.id < $1.id })
        let result: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: FittingAttribute)] = fittingAttributes.map { fittingAttribute in
            let attribute = ECKSDEManager.shared.itemAttribute(fittingAttribute.id)
            return (attribute: attribute, fittingAttribute: fittingAttribute)
        }.compactMap { attributes in
            guard let attribute = attributes.attribute else {
                return nil
            }
            
            return (attribute: attribute, fittingAttribute: attributes.fittingAttribute)
        }
        
        return result
    }
    
    internal var skills: [ECKCharacterFittingItem] = []
    
    init(description: String,
         fittingId: Int,
         items: [ECKCharacterFittingItem],
         name: String,
         ship: ECKItem) {
        self.description = description
        self.fittingId = fittingId
        self.items = items
        self.name = name
        self.ship = .init(flag: .ShipHangar,
                          quantity: 1,
                          item: ship)
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.fittingId = try container.decode(Int.self, forKey: .fittingId)
        self.items = try container.decode([ECKCharacterFittingItem].self, forKey: .items)
        self.name = try container.decode(String.self, forKey: .name)
        let ship = try container.decode(ECKItem.self, forKey: .ship)
        self.ship = .init(flag: .ShipHangar,
                          quantity: 1,
                          item: ship)
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
