//
//  ECKCharacterFitting+Calculate.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 26.05.25.
//

import Foundation

/// Reference: https://github.com/EVEShipFit/dogma-engine?tab=readme-ov-file#implementation

extension ECKCharacterFitting {
    
    internal enum ModifierDomain: String {
        case itemId
        case shipId
        case charId
        case otherId
        case structureId
        case target
        case targetId
        
        init?(rawValue: String?) {
            switch rawValue {
            case "ItemID":
                self = .itemId
            case "ShipID":
                self = .shipId
            case "CharID":
                self = .charId
            case "OtherID":
                self = .otherId
            case "StructureID":
                self = .structureId
            case "Target":
                self = .target
            case "TargetID":
                self = .targetId
            default:
                logger.warning("Cannot decode unknown modifier domain \(String(describing: rawValue))")
                self = .itemId
            }
        }
    }
    
    internal enum ModifierFunction: Int {
        case item = 0
        case locationGroup = 1
        case location = 2
        case locationRequiredSkill = 3
        case ownerRequiredSkill = 4
        case effectStopper = 5
        
        case unknown = -1
        
        init?(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .item
            case 1:
                self = .locationGroup
            case 2:
                self = .location
            case 3:
                self = .locationRequiredSkill
            case 4:
                self = .ownerRequiredSkill
            case 5:
                self = .effectStopper
            default:
                logger.error("Cannot get modifier function for \(rawValue)")
                self = .unknown
            }
        }
        
        init?(rawValue: String) {
            switch rawValue {
            case "ItemModifier":
                self = .item
            case "LocationGroupModifier":
                self = .locationGroup
            case "LocationModifier":
                self = .location
            case "LocationRequiredSkillModifier":
                self = .locationRequiredSkill
            case "OwnerRequiredSkillModifier":
                self = .ownerRequiredSkill
            case "EffectStopper":
                self = .effectStopper
            default:
                logger.error("Cannot get modifier function for \(rawValue)")
                self = .unknown
            }
        }
    }
    
    internal enum Modifier {
        case itemModifier
        case locationGroupModifier(groupId: Int)
        case locationModifier
        case locationRequiredSkillModifier(skillId: Int)
        case ownerRequiredSkillModifier(skillId: Int)
    }
    
    enum ItemObject {
        case ship
        case character
        case charge(index: Int)
        case item(index: Int)
        case skill(index: Int)
        case structure
        case target
    }
    
    internal enum ModifierOperation: Int {
        case preAssign = -1
        case preMul = 0
        case preDiv = 1
        case modAdd = 2
        case modSub = 3
        case postMul = 4
        case postDiv = 5
        case postPercent = 6
        case postAssign = 7
        
        init?(rawValue: Int?) {
            switch rawValue {
            case -1:
                self = .preMul
            case 0:
                self = .preMul
            case 1:
                self = .preDiv
            case 2:
                self = .modAdd
            case 3:
                self = .modSub
            case 4:
                self = .postMul
            case 5:
                self = .postDiv
            case 6:
                self = .postPercent
            case 7:
                self = .postAssign
            case 9:
                // Not needed.
                return nil
            default:
                logger.error("Cannot get modifier operation for \(String(describing: rawValue))")
                return nil
            }
        }
    }
    
    public class FittingAttribute {
        
        let baseValue: Float
        let value: Float?
        var effects: [FittingEffect]
        
        init(value: Float) {
            self.baseValue = value
            self.value = nil
            self.effects = []
        }
        
    }
    
    class FittingEffect {
        let operation: ModifierOperation
        let penalty: Bool
        let source: ItemObject
        let sourceCategory: ECKDogmaEffect.Category
        let sourceAttributeId: Int
        
        init(operation: ModifierOperation,
             penalty: Bool,
             source: ItemObject,
             sourceCategory: ECKDogmaEffect.Category,
             sourceAttributeId: Int) {
            self.operation = operation
            self.penalty = penalty
            self.source = source
            self.sourceCategory = sourceCategory
            self.sourceAttributeId = sourceAttributeId
        }
    }
    
    internal func calculateAttributes(skills: ECKCharacterSkills) {
        pass1(skills: skills)
        pass2()
        pass3()
        pass4()
    }
    
}
