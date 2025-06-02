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
        pass1CollectAttributes(for: ship.item, attributesDict: &self.attributes)
        
        let allSkills = ECKSDEManager.shared.getAllSkills()
        
        for skill in allSkills {
            let skill = ECKCharacterFittingSkill(skill: skill)
            pass1CollectAttributes(for: skill.skillItem, attributesDict: &skill.attributes)
            
            if let skillLevel = skills.skillSet[skill.skill.skillId] {
                skill.attributes[Self.attributeSkillLevelId] = .init(value: Float(skillLevel))
            } else {
                skill.attributes[Self.attributeSkillLevelId] = .init(value: 0)
            }
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
        let attributes: [ECKSDEManager.ItemAttribute] = item.itemAttributeCategories.flatMap({ $0.attributes })
        
        for attribute in attributes {
            attributesDict[attribute.id] = .init(value: attribute.value)
        }
        
        if let mass = item.mass {
            attributesDict[Self.attributeMassId] = .init(value: mass)
        }
        
        if let capacity = item.capacity {
            attributesDict[Self.attributeCapacityId] = .init(value: capacity)
        }
        
        if let volume = item.volume {
            attributesDict[Self.attributeVolumeId] = .init(value: volume)
        }
        
        if let radius = item.radius {
            attributesDict[Self.attributeRadiusId] = .init(value: radius)
        }
    }
    
}
