//
//  ECKCharacterFittingItem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation
public import Combine

public final class ECKCharacterFittingItem: Codable, Hashable, Identifiable, ObservableObject, @unchecked Sendable {
    
    private enum CodingKeys: String, CodingKey {
        case flag
        case quantity
        case item = "type_id"
        case charge
        case state
    }
    
    public var id: UUID
    
    public var flag: ECKItemLocationFlag
    @Published public var quantity: Int
    public let item: ECKItem
    
    public internal(set) var charge: ECKCharacterFittingItem?
    
    public internal(set) var attributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute] = [:]
    @Published public var state: ECKDogmaEffect.Category = .online
    internal var maxState: ECKDogmaEffect.Category = .offline

    private static func defaultState(for item: ECKItem) -> ECKDogmaEffect.Category {
        if item.isDrone || item.isFighter {
            return .active
        }

        return .online
    }
    
    public var userSettableStates: [ECKDogmaEffect.Category] {
        if maxState == .online {
            return [.offline, .online]
        } else {
            return [.offline, .online, .active, .overload].filter { category in
                return category.rawValue <= maxState.rawValue
            }
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
        
        if item.isFighter {
            struct FighterAbilityDamage {
                let damageMultiplierAttributeId: Int
                let emDamageAttributeId: Int
                let thermalDamageAttributeId: Int
                let kineticDamageAttributeId: Int
                let explosiveDamageAttributeId: Int
                let rateOfFireAttributeId: Int
            }
            
            let fighterSquadronSize = attributes[ECKCharacterFitting.attributeFighterSquadronSizeId]?.value ?? 1.0
            let abilityProfiles: [FighterAbilityDamage] = [
                .init(damageMultiplierAttributeId: ECKCharacterFitting.attributeFighterDamageMultiplierId,
                      emDamageAttributeId: ECKCharacterFitting.attributeFighterEMDamageId,
                      thermalDamageAttributeId: ECKCharacterFitting.attributeFighterThermalDamageId,
                      kineticDamageAttributeId: ECKCharacterFitting.attributeFighterKineticDamageId,
                      explosiveDamageAttributeId: ECKCharacterFitting.attributeFighterExplosiveDamageId,
                      rateOfFireAttributeId: ECKCharacterFitting.attributeFighterAbilityRoFId),
                .init(damageMultiplierAttributeId: 2130,
                      emDamageAttributeId: 2131,
                      thermalDamageAttributeId: 2132,
                      kineticDamageAttributeId: 2133,
                      explosiveDamageAttributeId: 2134,
                      rateOfFireAttributeId: ECKCharacterFitting.attributeFighterRoFId),
                .init(damageMultiplierAttributeId: 2178,
                      emDamageAttributeId: 2171,
                      thermalDamageAttributeId: 2172,
                      kineticDamageAttributeId: 2173,
                      explosiveDamageAttributeId: 2174,
                      rateOfFireAttributeId: 2177)
            ]
            
            var totalEM: Float = 0
            var totalKinetic: Float = 0
            var totalThermal: Float = 0
            var totalExplosive: Float = 0
            var totalEmDPS: Float = 0
            var totalKineticDPS: Float = 0
            var totalThermalDPS: Float = 0
            var totalExplosiveDPS: Float = 0
            var totalVolleyDamage: Float = 0
            var totalDPSWithoutReload: Float = 0
            
            for ability in abilityProfiles {
                let damageMultiplier = (attributes[ability.damageMultiplierAttributeId]?.value ?? 1.0) * fighterSquadronSize
                let emValue = (profileAttributes[ability.emDamageAttributeId]?.value ?? profileAttributes[ability.emDamageAttributeId]?.baseValue ?? 0) * damageMultiplier
                let kineticValue = (profileAttributes[ability.kineticDamageAttributeId]?.value ?? profileAttributes[ability.kineticDamageAttributeId]?.baseValue ?? 0) * damageMultiplier
                let thermalValue = (profileAttributes[ability.thermalDamageAttributeId]?.value ?? profileAttributes[ability.thermalDamageAttributeId]?.baseValue ?? 0) * damageMultiplier
                let explosiveValue = (profileAttributes[ability.explosiveDamageAttributeId]?.value ?? profileAttributes[ability.explosiveDamageAttributeId]?.baseValue ?? 0) * damageMultiplier
                let volleyDamage = emValue + kineticValue + thermalValue + explosiveValue
                
                guard volleyDamage > 0 else {
                    continue
                }
                
                let cycleTime = (attributes[ability.rateOfFireAttributeId]?.value ?? 0) / Float(MSEC_PER_SEC)
                
                totalEM += emValue
                totalKinetic += kineticValue
                totalThermal += thermalValue
                totalExplosive += explosiveValue
                totalVolleyDamage += volleyDamage
                
                guard cycleTime > 0 else {
                    continue
                }
                
                totalEmDPS += emValue / cycleTime
                totalKineticDPS += kineticValue / cycleTime
                totalThermalDPS += thermalValue / cycleTime
                totalExplosiveDPS += explosiveValue / cycleTime
                totalDPSWithoutReload += volleyDamage / cycleTime
            }
            
            return .init(em: totalEM,
                         explosive: totalExplosive,
                         kinetic: totalKinetic,
                         thermal: totalThermal,
                         emDPS: totalEmDPS,
                         explosiveDPS: totalExplosiveDPS,
                         kineticDPS: totalKineticDPS,
                         thermalDPS: totalThermalDPS,
                         volleyDamage: totalVolleyDamage,
                         dpsWithReload: totalDPSWithoutReload,
                         dpsWithoutReload: totalDPSWithoutReload)
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
        self.state = try container.decodeIfPresent(ECKDogmaEffect.Category.self, forKey: .state) ?? Self.defaultState(for: item)
    }
    
    public init(id: UUID = .init(), flag: ECKItemLocationFlag, quantity: Int, item: ECKItem) {
        self.id = id
        self.flag = flag
        self.quantity = quantity
        self.item = item
        self.state = Self.defaultState(for: item)
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
        try container.encode(state, forKey: .state)
    }
    
    func copy() -> ECKCharacterFittingItem {
        let copy = Self.init(id: id,
                             flag: flag,
                             quantity: quantity,
                             item: item)
        copy.state = state
        return copy
    }
    
}
