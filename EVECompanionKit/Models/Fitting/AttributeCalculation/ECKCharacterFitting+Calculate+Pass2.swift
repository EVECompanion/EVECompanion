//
//  ECKCharacterFitting+Calculate+Pass2.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

extension ECKCharacterFitting {
    
    internal func pass2() async {
        var effects: [ECKPass2Effect] = []
        
        if let velocityBonusEffect = ECKSDEManager.shared.getEffect(effectId: -1) {
            self.ship.collectEffect(effect: velocityBonusEffect, object: .ship, into: &effects)
        }
        
        self.ship.collectEffects(object: .ship, into: &effects)
        self.target.collectEffects(object: .target, into: &effects)
        self.structure.collectEffects(object: .structure, into: &effects)
        self.character.collectEffects(object: .character, into: &effects)
        // TODO: Boosters
        for (index, item) in items.enumerated() {
            item.collectEffects(object: .item(index: index), into: &effects)
            if let charge = item.charge {
                charge.collectEffects(object: .charge(index: index), into: &effects)
            }
        }
        
        for (index, skill) in skills.enumerated() {
            skill.collectEffects(object: .skill(index: index), into: &effects)
        }
        
        for effect in effects {
            let categoryId: Int
            var sourceTypeId: Int?
            
            switch effect.source {
            case .ship:
                categoryId = ship.item.itemCategory.categoryId
                sourceTypeId = ship.item.typeId
            case .character:
                categoryId = 1373
            case .charge(index: let index):
                categoryId = items[index].charge!.item.itemCategory.categoryId
                sourceTypeId = items[index].charge!.item.typeId
            case .item(index: let index):
                categoryId = items[index].item.itemCategory.categoryId
                sourceTypeId = items[index].item.typeId
            case .skill(index: let index):
                categoryId = skills[index].item.itemCategory.categoryId
                sourceTypeId = skills[index].item.typeId
            case .structure:
                continue
            case .target:
                continue
            }
            
            switch effect.modifier {
            case .itemModifier:
                let target: ECKCharacterFittingItem
                switch effect.target {
                case .ship:
                    target = ship
                case .character:
                    target = character
                case .charge(index: let index):
                    target = items[index].charge!
                case .item(index: let index):
                    target = items[index]
                case .skill(index: let index):
                    target = skills[index]
                case .structure:
                    target = self.structure
                case .target:
                    target = self.target
                }
                
                await target.addEffect(attributeId: effect.targetAttributeId,
                                       sourceCategoryId: categoryId,
                                       effect: effect)
            case .locationGroupModifier(groupId: let groupId):
                if ship.item.itemCategory.groupId == groupId {
                    await ship.addEffect(attributeId: effect.targetAttributeId,
                                         sourceCategoryId: categoryId,
                                         effect: effect)
                }
                
                for item in items {
                    if item.item.itemCategory.groupId == groupId {
                        await item.addEffect(attributeId: effect.targetAttributeId,
                                             sourceCategoryId: categoryId,
                                             effect: effect)
                    }
                    
                    if let charge = item.charge,
                       charge.item.itemCategory.groupId == groupId {
                        await charge.addEffect(attributeId: effect.targetAttributeId,
                                               sourceCategoryId: categoryId,
                                               effect: effect)
                    }
                }
            case .locationModifier:
                await ship.addEffect(attributeId: effect.targetAttributeId,
                                     sourceCategoryId: categoryId,
                                     effect: effect)
                
                for item in items {
                    await item.addEffect(attributeId: effect.targetAttributeId,
                                         sourceCategoryId: categoryId,
                                         effect: effect)
                    
                    if let charge = item.charge {
                        await charge.addEffect(attributeId: effect.targetAttributeId,
                                               sourceCategoryId: categoryId,
                                               effect: effect)
                    }
                }
                
            case .ownerRequiredSkillModifier(skillId: let skillId),
                 .locationRequiredSkillModifier(skillId: let skillId):
                // requiredSkill1, requiredSkill2, ...
                let actualSkillId: Int
                
                if let sourceTypeId, skillId == -1 {
                    actualSkillId = sourceTypeId
                } else {
                    actualSkillId = skillId
                }
                
                for attributeId in [182, 183, 184, 1285, 1289, 1290] {
                    if let attribute = ship.attributes[attributeId],
                       Int(attribute.baseValue) == actualSkillId {
                        await ship.addEffect(attributeId: effect.targetAttributeId,
                                             sourceCategoryId: categoryId,
                                             effect: effect)
                    }
                    
                    for item in items {
                        if let attribute = item.attributes[attributeId],
                           Int(attribute.baseValue) == actualSkillId {
                            await item.addEffect(attributeId: effect.targetAttributeId,
                                                 sourceCategoryId: categoryId,
                                                 effect: effect)
                        }
                        
                        if let charge = item.charge,
                           let attribute = charge.attributes[attributeId],
                           Int(attribute.baseValue) == actualSkillId {
                            await charge.addEffect(attributeId: effect.targetAttributeId,
                                                   sourceCategoryId: categoryId,
                                                   effect: effect)
                        }
                    }
                }
            }
        }
    }
    
}

struct ECKPass2Effect {
    let effectId: Int
    let modifier: ECKCharacterFitting.Modifier
    let operation: ECKCharacterFitting.ModifierOperation
    let source: ECKCharacterFitting.ItemObject
    let sourceCategory: ECKDogmaEffect.Category
    let sourceAttributeId: ECKCharacterFitting.AttributeID
    let target: ECKCharacterFitting.ItemObject
    let targetAttributeId: ECKCharacterFitting.AttributeID
}

fileprivate extension ECKCharacterFittingItem {
    
    var penaltyExemptCategories: [Int] {
        return [
            6,  // Ship
            8,  // Charge
            16, // Skill
            20, // Implant
            32  // Subsystem
        ]
    }
    
    func addEffect(attributeId: Int, sourceCategoryId: Int, effect: ECKPass2Effect) async {
        var attribute: ECKCharacterFitting.FittingAttribute
        if let existingAttribute = self.attributes[attributeId] {
            attribute = existingAttribute
        } else {
            
            guard let defaultValue = await ECKAttributeDefaultValueCache.shared.getDefaultValue(for: attributeId) else {
                logger.error("Cannot get default value for attribute ID \(attributeId)")
                return
            }
            
            attribute = .init(id: attributeId, defaultValue: defaultValue)
            self.attributes[attributeId] = attribute
        }
        
        let penalty = penaltyExemptCategories.contains(sourceCategoryId) == false
        && ECKSDEManager.shared.getAttribute(id: attributeId).stackable == false
        
        let effect = ECKCharacterFitting.FittingEffect(effectId: effect.effectId,
                                                       operation: effect.operation,
                                                       penalty: penalty,
                                                       source: effect.source,
                                                       sourceCategory: effect.sourceCategory,
                                                       sourceAttributeId: effect.sourceAttributeId)
        attribute.effects.append(effect)
    }
    
    func collectEffects(object: ECKCharacterFitting.ItemObject, into collectedEffects: inout [ECKPass2Effect]) {
        let effects = ECKSDEManager.shared.getEffects(for: item.typeId)
        
        for effect in effects {
            collectEffect(effect: effect, object: object, into: &collectedEffects)
        }
    }
    
    func collectEffect(effect: ECKDogmaEffect, object: ECKCharacterFitting.ItemObject, into collectedEffects: inout [ECKPass2Effect]) {
        if effect.category.rawValue > self.maxState.rawValue {
            self.maxState = effect.category
        }
        
        for modifierInfo in effect.modifierInfo {
            let modifier = getModifier(for: modifierInfo)
            guard let modifier else {
                continue
            }
            
            let operationId = modifierInfo["operation"] as? Int
            guard let operation = ECKCharacterFitting.ModifierOperation(rawValue: operationId) else {
                continue
            }
            
            let domainString = modifierInfo["domain"] as? String
            guard let domain = ECKCharacterFitting.ModifierDomain(rawValue: domainString) else {
                logger.error("Domain is not set.")
                continue
            }
            
            if case .item = object, domain == .otherId {
                continue
            }
            
            let target: ECKCharacterFitting.ItemObject
            
            switch domain {
            case .itemId:
                target = object
            case .shipId:
                target = .ship
            case .charId:
                target = .character
            case .otherId:
                switch object {
                case .item(index: let index):
                    target = .charge(index: index)
                case .charge(index: let index):
                    target = .item(index: index)
                default:
                    logger.error("Unexpected target for other id \(object)")
                    continue
                }
            case .structureId:
                target = .structure
            case .target:
                target = .target
            case .targetId:
                target = .target
            }
            
            guard let modifiedAttributeID = modifierInfo["modifiedAttributeID"] as? Int else {
                logger.warning("Modifier Info has no modifiedAttributeID.")
                continue
            }
            
            guard let modifyingAttributeID = modifierInfo["modifyingAttributeID"] as? Int else {
                logger.warning("Modifier Info has no modifyingAttributeID.")
                continue
            }
            
            collectedEffects.append(.init(effectId: effect.id,
                                          modifier: modifier,
                                          operation: operation,
                                          source: object,
                                          sourceCategory: effect.category,
                                          sourceAttributeId: modifyingAttributeID,
                                          target: target,
                                          targetAttributeId: modifiedAttributeID))
        }
    }
    
    private func getModifier(for modifierInfo: [String: Any]) -> ECKCharacterFitting.Modifier? {
        guard let functionIdentifier = modifierInfo["func"] as? String else {
            logger.warning("Cannot get modifier func from \(modifierInfo)")
            return nil
        }
        
        guard let parsedFunc = ECKCharacterFitting.ModifierFunction(rawValue: functionIdentifier) else {
            return nil
        }
        
        let skillTypeId: Int? = modifierInfo["skillTypeID"] as? Int
        let groupId: Int? = modifierInfo["groupID"] as? Int
        
        switch parsedFunc {
        case .item:
            return .itemModifier
        case .locationGroup:
            guard let groupId else {
                logger.error("Cannot get required groupId for locationGroup modifier.")
                return nil
            }
            
            return .locationGroupModifier(groupId: groupId)
        case .location:
            return .locationModifier
        case .locationRequiredSkill:
            guard let skillTypeId else {
                logger.error("Cannot get required skill type id for locationRequiredSkill modifier.")
                return nil
            }
            
            return .locationRequiredSkillModifier(skillId: skillTypeId)
        case .ownerRequiredSkill:
            guard let skillTypeId else {
                logger.error("Cannot get required skill type id for ownerRequiredSkill modifier.")
                return nil
            }
            
            return .ownerRequiredSkillModifier(skillId: skillTypeId)
        case .effectStopper:
            return nil
        case .unknown:
            return nil
        }
    }
    
}
