//
//  ECKCharacterFitting+Calculate+Pass1.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

extension ECKCharacterFitting {
    
    /// Collect DGM Attributes of hull and modules. (pass 1 in reference)
    internal func pass1(skills: ECKCharacterSkills) {
        pass1CollectAttributes(for: ship.item, attributesDict: &ship.attributes)
        
        for skill in skills.skillLevels {
            let item = ECKCharacterFittingItem(flag: .Skill, quantity: 1, item: .init(typeId: skill.skill.skillId))
            pass1CollectAttributes(for: item.item, attributesDict: &item.attributes)
            
            item.attributes[Self.attributeSkillLevelId] = .init(id: Self.attributeSkillLevelId,
                                                                defaultValue: Float(skill.trainedSkillLevel))
            item.attributes[Self.attributeSkillLevelId]?.value = Float(skill.trainedSkillLevel)
            
            self.skills.append(item)
        }
        
        for item in items {
            switch item.flag {
                
            case .DroneBay,
                    .FighterTube0,
                    .FighterTube1,
                    .FighterTube2,
                    .FighterTube3,
                    .FighterTube4,
                    .HiSlot0,
                    .HiSlot1,
                    .HiSlot2,
                    .HiSlot3,
                    .HiSlot4,
                    .HiSlot5,
                    .HiSlot6,
                    .HiSlot7,
                    .LoSlot0,
                    .LoSlot1,
                    .LoSlot2,
                    .LoSlot3,
                    .LoSlot4,
                    .LoSlot5,
                    .LoSlot6,
                    .LoSlot7,
                    .MedSlot0,
                    .MedSlot1,
                    .MedSlot2,
                    .MedSlot3,
                    .MedSlot4,
                    .MedSlot5,
                    .MedSlot6,
                    .MedSlot7,
                    .RigSlot0,
                    .RigSlot1,
                    .RigSlot2,
                    .RigSlot3,
                    .RigSlot4,
                    .RigSlot5,
                    .RigSlot6,
                    .RigSlot7,
                    .SubSystemSlot0,
                    .SubSystemSlot1,
                    .SubSystemSlot2,
                    .SubSystemSlot3,
                    .SubSystemSlot4,
                    .SubSystemSlot5,
                    .SubSystemSlot6,
                    .SubSystemSlot7:
                pass1CollectAttributes(for: item.item, attributesDict: &item.attributes)
                if let charge = item.charge {
                    pass1CollectAttributes(for: charge.item, attributesDict: &charge.attributes)
                }
                
            case .unknown,
                    .AssetSafety,
                    .AutoFit,
                    .BoosterBay,
                    .Cargo,
                    .CorporationGoalDeliveries,
                    .CorpseBay,
                    .Deliveries,
                    .FighterBay,
                    .FleetHangar,
                    .FrigateEscapeBay,
                    .Hangar,
                    .HangarAll,
                    .HiddenModifiers,
                    .Implant,
                    .Locked,
                    .MobileDepotHold,
                    .QuafeBay,
                    .ShipHangar,
                    .Skill,
                    .SpecializedAmmoHold,
                    .SpecializedAsteroidHold,
                    .SpecializedCommandCenterHold,
                    .SpecializedFuelBay,
                    .SpecializedGasHold,
                    .SpecializedIceHold,
                    .SpecializedIndustrialShipHold,
                    .SpecializedLargeShipHold,
                    .SpecializedMaterialBay,
                    .SpecializedMediumShipHold,
                    .SpecializedMineralHold,
                    .SpecializedOreHold,
                    .SpecializedPlanetaryCommoditiesHold,
                    .SpecializedSalvageHold,
                    .SpecializedShipHold,
                    .SpecializedSmallShipHold,
                    .StructureDeedBay,
                    .SubSystemBay,
                    .Unlocked,
                    .Wardrobe:
                continue
            }
        }
    }
    
    private func pass1CollectAttributes(for item: ECKItem, attributesDict: inout [AttributeID: FittingAttribute]) {
        let attributes = ECKSDEManager.shared.itemAttributes(item.typeId, includeNonUIAttributes: true).flatMap({ $0.attributes })
        
        for attribute in attributes {
            attributesDict[attribute.id] = .init(id: attribute.id, defaultValue: attribute.value)
        }
        
        if let mass = item.mass {
            attributesDict[Self.attributeMassId] = .init(id: Self.attributeMassId, defaultValue: mass)
        }
        
        if let capacity = item.capacity {
            attributesDict[Self.attributeCapacityId] = .init(id: Self.attributeCapacityId, defaultValue: capacity)
        }
        
        if let volume = item.volume {
            attributesDict[Self.attributeVolumeId] = .init(id: Self.attributeVolumeId, defaultValue: volume)
        }
        
        if let radius = item.radius {
            attributesDict[Self.attributeRadiusId] = .init(id: Self.attributeRadiusId, defaultValue: radius)
        }
    }
    
}
