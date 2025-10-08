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
            switch rawValue?.lowercased() {
            case "itemid":
                self = .itemId
            case "shipid":
                self = .shipId
            case "charid":
                self = .charId
            case "otherid":
                self = .otherId
            case "structureid":
                self = .structureId
            case "target":
                self = .target
            case "targetid":
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
    
    internal enum ModifierOperation: Int, CaseIterable {
        case preAssign = -1
        case preMul = 0
        case preDiv = 1
        case modAdd = 2
        case modSub = 3
        case postMul = 4
        case postDiv = 5
        case postPercent = 6
        case postAssign = 7
        
        var hasPenalty: Bool {
            switch self {
            case .preAssign:
                return false
            case .preMul:
                return true
            case .preDiv:
                return true
            case .modAdd:
                return false
            case .modSub:
                return false
            case .postMul:
                return true
            case .postDiv:
                return true
            case .postPercent:
                return true
            case .postAssign:
                return false
            }
        }
        
        init?(rawValue: Int?) {
            switch rawValue {
            case -1:
                self = .preAssign
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
        
        public let id: Int
        public let baseValue: Float
        public var value: Float?
        var effects: [FittingEffect]
        
        public init(id: Int, defaultValue: Float) {
            self.id = id
            self.baseValue = defaultValue
            self.value = nil
            self.effects = []
        }
        
    }
    
    class FittingEffect {
        let effectId: Int
        let operation: ModifierOperation
        let penalty: Bool
        let source: ItemObject
        let sourceCategory: ECKDogmaEffect.Category
        let sourceAttributeId: Int
        
        init(effectId: Int,
             operation: ModifierOperation,
             penalty: Bool,
             source: ItemObject,
             sourceCategory: ECKDogmaEffect.Category,
             sourceAttributeId: Int) {
            self.effectId = effectId
            self.operation = operation
            self.penalty = penalty
            self.source = source
            self.sourceCategory = sourceCategory
            self.sourceAttributeId = sourceAttributeId
        }
    }
    
    @MainActor
    public func calculateAttributes(skills: ECKCharacterSkills?) async {
        if let currentAttributeCalculationTask {
            _ = await currentAttributeCalculationTask.value
        }
        
        currentAttributeCalculationTask = Task {
            self.ship.attributes.removeAll()
            self.target.attributes.removeAll()
            self.structure.attributes.removeAll()
            self.items.forEach({
                $0.attributes.removeAll()
                $0.charge?.attributes.removeAll()
            })
            self.skills.removeAll()
            if let skills {
                self.lastUsedSkills = skills
            }
            
            
            pass1(skills: skills ?? lastUsedSkills ?? .empty)
            await pass2()
            await pass3()
            pass4()
            
            await MainActor.run {
                self.objectWillChange.send()
                self.items.forEach {
                    $0.objectWillChange.send()
                }
            }
            
            currentAttributeCalculationTask = nil
        }
    }
    
}
