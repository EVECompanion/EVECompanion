//
//  ECKCharacterFittingItem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation
public import Combine

public class ECKCharacterFittingItem: Codable, Hashable, Identifiable, ObservableObject {
    
    private enum CodingKeys: String, CodingKey {
        case flag
        case quantity
        case item = "type_id"
        case charge
    }
    
    public var id: UUID
    
    public var flag: ECKItemLocationFlag
    @Published public var quantity: Int
    public let item: ECKItem
    
    public internal(set) var charge: ECKCharacterFittingItem?
    
    public internal(set) var attributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute] = [:]
    @Published public var state: ECKDogmaEffect.Category = .active
    internal var maxState: ECKDogmaEffect.Category = .passive
    
    public var userSettableStates: [ECKDogmaEffect.Category] {
        return [.passive, .active, .overload].filter { category in
            return category.rawValue <= maxState.rawValue
        }
    }
    
    internal lazy var usesLauncherSlot: Bool = {
        let effects = ECKSDEManager.shared.getEffects(for: item.typeId)
        return effects.first(where: { $0.id == 40 }) != nil
    }()
    
    internal lazy var usesTurretSlot: Bool = {
        let effects = ECKSDEManager.shared.getEffects(for: item.typeId)
        return effects.first(where: { $0.id == 42 }) != nil
    }()
    
    public lazy var canUseCharges: Bool = {
        return ECKSDEManager.shared.canUseCharges(typeId: item.typeId)
    }()
    
    public var damageProfile: ECKCharacterFitting.DamageProfile? {
        guard self.state.rawValue >= ECKDogmaEffect.Category.active.rawValue else {
            return nil
        }
        
        let profileAttributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute]
        
        if let charge {
            profileAttributes = charge.attributes
        } else {
            profileAttributes = attributes
        }
        
        let em = profileAttributes[ECKCharacterFitting.attributeEMDamageId]
        let kinetic = profileAttributes[ECKCharacterFitting.attributeKineticDamageId]
        let thermal = profileAttributes[ECKCharacterFitting.attributeThermalDamageId]
        let explosive = profileAttributes[ECKCharacterFitting.attributeExplosiveDamageId]
        
        let damageMultiplier: Float
        
        let regularDamageMultiplierAttribute = attributes[ECKCharacterFitting.attributeDamageMultiplierId]
        let regularDamageMultiplierValue = regularDamageMultiplierAttribute?.value ?? 1.0
        let missileDamageMultiplierAttribute = attributes[ECKCharacterFitting.attributeMissileDamageMultiplierId]
        let missileDamageMultiplierValue = missileDamageMultiplierAttribute?.value ?? 1.0
        
        if let charge, charge.item.skillRequirements?.contains(where: { $0.skill.id == 3319 }) ?? false {
            damageMultiplier = missileDamageMultiplierValue * Float(quantity)
        } else {
            damageMultiplier = regularDamageMultiplierValue * Float(quantity)
        }
        
        let emValue = (em?.value ?? em?.baseValue ?? 0) * damageMultiplier
        let kineticValue = (kinetic?.value ?? kinetic?.baseValue ?? 0) * damageMultiplier
        let thermalValue = (thermal?.value ?? thermal?.baseValue ?? 0) * damageMultiplier
        let explosiveValue = (explosive?.value ?? explosive?.baseValue ?? 0) * damageMultiplier
        let volleyDamage = emValue + kineticValue + thermalValue + explosiveValue
        
        let chargeSize = attributes[ECKCharacterFitting.attributeChargeSizeId]?.value ?? 0
        let rateOfFire = attributes[ECKCharacterFitting.attributeRoFId]?.value ?? 0
        let activationTime = attributes[ECKCharacterFitting.attributeActivationTimeId]?.value ?? 0
        let activationTime2 = attributes[ECKCharacterFitting.attributeActivationTimeHighIsGoodId]?.value ?? 0
        let cycleTime = max(rateOfFire, activationTime, activationTime2) / Float(MSEC_PER_SEC)
        let reloadTime = (attributes[ECKCharacterFitting.attributeReloadTimeId]?.value ?? 10_000) / Float(MSEC_PER_SEC)
        
        let emDPS: Float
        let kineticDPS: Float
        let thermalDPS: Float
        let explosiveDPS: Float
        let dpsWithoutReload: Float
        
        if cycleTime > 0 {
            emDPS = emValue / cycleTime
            kineticDPS = kineticValue / cycleTime
            thermalDPS = thermalValue / cycleTime
            explosiveDPS = explosiveValue / cycleTime
            dpsWithoutReload = volleyDamage / cycleTime
        } else {
            emDPS = 0
            kineticDPS = 0
            thermalDPS = 0
            explosiveDPS = 0
            dpsWithoutReload = 0
        }
        
        let dpsWithReload: Float
        
        if chargeSize > 0, cycleTime > 0 {
            let cycleDamage = volleyDamage * chargeSize
            dpsWithReload = cycleDamage / (cycleTime * chargeSize + reloadTime)
        } else {
            dpsWithReload = dpsWithoutReload
        }
        
        return .init(em: emValue,
                     explosive: explosiveValue,
                     kinetic: kineticValue,
                     thermal: thermalValue,
                     emDPS: emDPS,
                     explosiveDPS: explosiveDPS,
                     kineticDPS: kineticDPS,
                     thermalDPS: thermalDPS,
                     volleyDamage: volleyDamage,
                     dpsWithReload: dpsWithReload,
                     dpsWithoutReload: dpsWithoutReload)
    }
    
    #if DEBUG
    public var debugFittingAttributes: [(attribute: ECKSDEManager.ItemAttribute, fittingAttribute: ECKCharacterFitting.FittingAttribute)] {
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
    #endif
    
    public required init(from decoder: any Decoder) throws {
        self.id = .init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.flag = try container.decode(ECKItemLocationFlag.self, forKey: .flag)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.item = try container.decode(ECKItem.self, forKey: .item)
        self.charge = try container.decodeIfPresent(ECKCharacterFittingItem.self, forKey: .charge)
    }
    
    public init(id: UUID = .init(), flag: ECKItemLocationFlag, quantity: Int, item: ECKItem) {
        self.id = id
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
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(flag, forKey: .flag)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(item, forKey: .item)
        try container.encodeIfPresent(charge, forKey: .charge)
    }
    
    func copy() -> ECKCharacterFittingItem {
        return .init(id: id,
                     flag: flag,
                     quantity: quantity,
                     item: item)
    }
    
}
