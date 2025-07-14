//
//  ECKCharacterFittingItem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

public class ECKCharacterFittingItem: Decodable, Hashable, Identifiable {
    
    private enum CodingKeys: String, CodingKey {
        case flag
        case quantity
        case item = "type_id"
    }
    
    public var id: UUID = UUID()
    
    public let flag: ECKItemLocationFlag
    public let quantity: Int
    public let item: ECKItem
    
    public var charge: ECKCharacterFittingItem?
    
    public internal(set) var attributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute] = [:]
    public var state: ECKDogmaEffect.Category = .active
    internal var maxState: ECKDogmaEffect.Category = .passive
    
    internal lazy var usesLauncherSlot: Bool = {
        let effects = ECKSDEManager.shared.getEffects(for: item.typeId)
        return effects.first(where: { $0.id == 40 }) != nil
    }()
    
    internal lazy var usesTurretSlot: Bool = {
        let effects = ECKSDEManager.shared.getEffects(for: item.typeId)
        return effects.first(where: { $0.id == 42 }) != nil
    }()
    
    // TODO: Remove, Debug Only!
    public var fittingAttributes: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: ECKCharacterFitting.FittingAttribute)] {
        var fittingAttributes: [ECKCharacterFitting.FittingAttribute] = Array(attributes.values)
        fittingAttributes.sort(by: { $0.id < $1.id })
        let result: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: ECKCharacterFitting.FittingAttribute)] = fittingAttributes.map { fittingAttribute in
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
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.flag = try container.decode(ECKItemLocationFlag.self, forKey: .flag)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.item = try container.decode(ECKItem.self, forKey: .item)
    }
    
    public init(flag: ECKItemLocationFlag, quantity: Int, item: ECKItem) {
        self.flag = flag
        self.quantity = quantity
        self.item = item
    }
    
    public static func == (lhs: ECKCharacterFittingItem, rhs: ECKCharacterFittingItem) -> Bool {
        return lhs.flag == rhs.flag
        && lhs.quantity == rhs.quantity
        && lhs.item == rhs.item
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(flag)
        hasher.combine(quantity)
        hasher.combine(item)
    }
    
}
