//
//  ECKCharacterFitting+IsFittable.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 06.10.25.
//

import Foundation

extension ECKCharacterFitting {
    
    func checkItemIsFittable(item: ECKItem) throws(ECKAddModuleError) {
        guard item.slotType != nil else {
            throw .moduleNotFittable(item)
        }
        
        let itemAttributes = ECKSDEManager.shared.itemAttributes(item.typeId, includeNonUIAttributes: true).flatMap({ $0.attributes })
        
        var itemAttributesDict: [Int: ECKSDEManager.ItemAttribute] = [:]
        
        for itemAttribute in itemAttributes {
            itemAttributesDict[itemAttribute.id] = itemAttribute
        }
        
        let moduleEffects = ECKSDEManager.shared.getEffects(for: item.typeId)
        
        try checkItemIsFittableToShipType(item: item, itemAttributes: itemAttributesDict)
        try checkItemNumberFittingRestrictions(item: item, itemAttributes: itemAttributesDict)
        try checkHardpointLimits(item: item, moduleEffects: moduleEffects)
        try checkSubsystemShipCompatibility(item: item,
                                            itemAttributes: itemAttributesDict,
                                            itemEffects: moduleEffects)
    }
    
    private func checkItemIsFittableToShipType(item: ECKItem, itemAttributes: [Int: ECKSDEManager.ItemAttribute]) throws(ECKAddModuleError) {
        let restrictionAttributes = ECKSDEManager.shared.getItemFittingRestrictionAttributes()
        
        // Check if the item has any restrictions and return early
        
        var itemHasRestrictions: Bool = false
        
        for restrictionAttribute in restrictionAttributes {
            switch restrictionAttribute {
            case .canFitToShipType(let attributeId):
                if let attribute = itemAttributes[attributeId] {
                    let shipTypeId = Int(attribute.value)
                    itemHasRestrictions = true
                    if shipTypeId == ship.item.typeId {
                        return
                    }
                }
            case .canFitToShipGroup(let attributeId):
                if let attribute = itemAttributes[attributeId] {
                    let groupId = Int(attribute.value)
                    itemHasRestrictions = true
                    if groupId == ship.item.itemCategory.groupId {
                        return
                    }
                }
            }
        }
        
        if itemHasRestrictions {
            throw .moduleNotFittable(item)
        } else {
            return
        }
    }
    
    private func checkItemNumberFittingRestrictions(item: ECKItem, itemAttributes: [Int: ECKSDEManager.ItemAttribute]) throws(ECKAddModuleError) {
        if let maxNumberRestrictionAttribute = itemAttributes[1544] {
            let maxNumberOfItemGroup: Int = Int(maxNumberRestrictionAttribute.value)
            let currentNumberOfFittedItemsInGroup = self.items.filter({ $0.item.itemCategory.groupId == item.itemCategory.groupId }).count
            if currentNumberOfFittedItemsInGroup + 1 > maxNumberOfItemGroup {
                throw .moduleMaxCountReached(group: item.itemCategory.group, maxCount: maxNumberOfItemGroup)
            }
        }
    }
    
    private func checkHardpointLimits(item: ECKItem, moduleEffects: [ECKDogmaEffect]) throws(ECKAddModuleError) {
        // Check if the item needs a launcher hardpoint
        if moduleEffects.contains(where: { $0.id == 40 }) {
            if self.usedLauncherHardPoints < self.launcherHardPoints {
                return
            } else {
                throw .notEnoughLauncherHardpoints
            }
        // Check if the item needs a turret hardpoint
        } else if moduleEffects.contains(where: { $0.id == 42 }) {
            if self.usedTurretHardPoints < self.turretHardPoints {
                return
            } else {
                throw .notEnoughTurretHardpoints
            }
        } else {
            return
        }
    }
    
    private func checkSubsystemShipCompatibility(item: ECKItem,
                                                 itemAttributes: [Int: ECKSDEManager.ItemAttribute],
                                                 itemEffects: [ECKDogmaEffect]) throws(ECKAddModuleError) {
        guard itemEffects.contains(where: { $0.id == 3772 }) else {
            // The new module is not a subsystem, skip this check.
            return
        }
        
        guard let fitsToShipAttribute = itemAttributes[1380] else {
            logger.error("Module is a subsystem but has no fit restriction attribute set.")
            throw .generic
        }
        
        let compatibleShipTypeId: Int = Int(fitsToShipAttribute.value)
        
        guard ship.item.typeId == compatibleShipTypeId else {
            throw .subsystemIncompatible(item)
        }
        
        // Check if there is already a subsystem in this slot type.
        guard let newSubsystemSlotAttribute = itemAttributes[1366] else {
            throw .generic
        }
        
        let newSubsystemSlotId: Int = Int(newSubsystemSlotAttribute.value)
        
        for subsystem in self.subsystems {
            if let subsystemSlotAttribute = subsystem.attributes[1366] {
                let subsystemSlotId: Int = Int(subsystemSlotAttribute.value ?? subsystemSlotAttribute.baseValue)
                
                guard subsystemSlotId == newSubsystemSlotId else {
                    continue
                }
                
                throw .subsystemSlotAlreadyOccupied(item, fittedSubsystem: subsystem.item)
            }
        }
    }
    
}
