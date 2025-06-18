//
//  ECKCharacterFitting+Calculate+Pass3.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

private let PENALTY_FACTOR: Float = 0.8691199808003974

extension ECKCharacterFitting {
    
    private class AttributesCache {
        var ship: [Int: Float] = [:]
        var items: [Int: [Int: Float]] = [:]
        var charge: [Int: [Int: Float]] = [:]
        var skills: [Int: [Int: Float]] = [:]
        
        init() { }
    }
    
    internal func pass3() {
        let cache = AttributesCache()
        
        for (index, skill) in self.skills.enumerated() {
            cache.skills[index]?[Self.attributeSkillLevelId] = skill.attributes[Self.attributeSkillLevelId]?.baseValue
        }
        
        calculateValues(ship: ship, itemObject: .ship, cache: cache)
        // TODO: Character value calculation
        for (index, item) in items.enumerated() {
            calculateValues(ship: ship, itemObject: .item(index: index), cache: cache)
            if let charge = item.charge {
                calculateValues(ship: ship, itemObject: .charge(index: index), cache: cache)
            }
        }
        
        for (index, skill) in self.skills.enumerated() {
            calculateValues(ship: ship,
                            itemObject: .skill(index: index),
                            cache: cache)
        }
        
        // TODO
        storeCachedValues(for: ship, cache: cache.ship)
        
        for (index, item) in items.enumerated() {
            storeCachedValues(for: item, cache: cache.items[index] ?? [:])
            if let charge = item.charge {
                storeCachedValues(for: charge, cache: cache.charge[index] ?? [:])
            }
        }
        
        for (index, skill) in self.skills.enumerated() {
            storeCachedValues(for: skill, cache: cache.skills[index] ?? [:])
        }
    }
    
    private func calculateValues(ship: ECKCharacterFittingItem,
                                 itemObject: ECKCharacterFitting.ItemObject,
                                 cache: AttributesCache) {
        for attribute in ship.attributes.values {
            calculateValue(for: attribute,
                           ship: ship,
                           attributeId: attribute.id,
                           itemObject: itemObject,
                           cache: cache)
        }
    }
    
    private func storeCachedValues(for item: ECKCharacterFittingItem, cache: [Int: Float]) {
        for (attributeId, value) in cache {
            if let attribute = item.attributes[attributeId] {
                attribute.value = value
            } else if let defaultValue = ECKSDEManager.shared.getAttributeDefaultValue(attributeId: attributeId) {
                let fittingAttribute = FittingAttribute(id: attributeId, defaultValue: defaultValue)
                fittingAttribute.value = value
                
                item.attributes[attributeId] = fittingAttribute
            } else {
                logger.error("Cannot get default value for \(attributeId)")
                continue
            }
        }
    }
    
    @discardableResult
    private func calculateValue(for attribute: ECKCharacterFitting.FittingAttribute,
                                ship: ECKCharacterFittingItem,
                                attributeId: Int,
                                itemObject: ECKCharacterFitting.ItemObject,
                                cache: AttributesCache) -> Float {
        
        var currentValue = attribute.baseValue
        
        if let value = attribute.value {
            return value
        }
        
        var cacheValue: Float?
        
        switch itemObject {
        case .ship:
            cacheValue = cache.ship[attributeId]
        case .character:
            ()
        case .charge(index: let index):
            cacheValue = cache.charge[index]?[attributeId]
        case .item(index: let index):
            cacheValue = cache.items[index]?[attributeId]
        case .skill(index: let index):
            cacheValue = cache.skills[index]?[attributeId]
        case .structure:
            ()
        case .target:
            ()
        }
        
        if let cacheValue {
            return cacheValue
        }
        
        for operation in ECKCharacterFitting.ModifierOperation.allCases {
            var nonPenaltyValues: [Float] = []
            var positivePenaltyValues: [Float] = []
            var negativePenaltyValues: [Float] = []
            
            for effect in attribute.effects {
                guard effect.operation == operation else {
                    continue
                }
                
                let source: ECKCharacterFittingItem
                
                switch effect.source {
                case .ship:
                    source = ship
                case .character:
                    // TODO
                    continue
                case .charge(index: let index):
                    guard let charge = items[index].charge else {
                        continue
                    }
                    
                    source = charge
                case .item(index: let index):
                    source = items[index]
                case .skill(index: let index):
                    source = skills[index]
                case .structure:
                    // TODO?
                    continue
                case .target:
                    // TODO
                    continue
                }
                
                if effect.sourceCategory.rawValue > source.state.rawValue {
                    continue
                }
                
                var sourceValue: Float
                
                if let sourceAttribute = source.attributes[effect.sourceAttributeId] {
                    sourceValue = calculateValue(for: sourceAttribute,
                                                 ship: ship,
                                                 attributeId: effect.sourceAttributeId,
                                                 itemObject: effect.source,
                                                 cache: cache)
                } else {
                    guard let defaultValue = ECKSDEManager.shared.getAttributeDefaultValue(attributeId: effect.sourceAttributeId) else {
                        continue
                    }
                    
                    sourceValue = defaultValue
                }
                
                switch operation {
                case .preAssign:
                    ()
                case .preMul:
                    sourceValue -= 1.0
                case .preDiv:
                    sourceValue = 1.0 / sourceValue - 1.0
                case .modAdd:
                    ()
                case .modSub:
                    sourceValue = -sourceValue
                case .postMul:
                    sourceValue -= 1.0
                case .postDiv:
                    sourceValue = 1.0 / sourceValue - 1.0
                case .postPercent:
                    sourceValue /= 100.0
                case .postAssign:
                    ()
                }
                
                if effect.penalty && effect.operation.hasPenalty {
                    if sourceValue < 0.0 {
                        negativePenaltyValues.append(sourceValue)
                    } else {
                        positivePenaltyValues.append(sourceValue)
                    }
                } else {
                    nonPenaltyValues.append(sourceValue)
                }
                
                if nonPenaltyValues.isEmpty && positivePenaltyValues.isEmpty && negativePenaltyValues.isEmpty {
                    continue
                }
                
                switch operation {
                case .preAssign,
                     .postAssign:
                    let attribute = ECKSDEManager.shared.getAttribute(id: attributeId)
                    if attribute.highIsGood {
                        currentValue = nonPenaltyValues.max(by: { lhs, rhs in
                            return abs(lhs) < abs(rhs)
                        })!
                    } else {
                        currentValue = nonPenaltyValues.min(by: { lhs, rhs in
                            return abs(lhs) < abs(rhs)
                        })!
                    }
                    
                case .preMul,
                     .preDiv,
                     .postMul,
                     .postDiv,
                     .postPercent:
                    for value in nonPenaltyValues {
                        currentValue *= 1.0 + value
                    }
                    
                    positivePenaltyValues.sort()
                    positivePenaltyValues.reverse()
                    
                    for (index, value) in positivePenaltyValues.enumerated() {
                        currentValue *= 1.0 + value * pow(PENALTY_FACTOR, pow(Float(index), 2))
                    }
                    
                    negativePenaltyValues.sort()
                    
                    for (index, value) in negativePenaltyValues.enumerated() {
                        currentValue *= 1.0 + value * pow(PENALTY_FACTOR, pow(Float(index), 2))
                    }
                    
                case .modAdd,
                     .modSub:
                    for value in nonPenaltyValues {
                        currentValue += value
                    }
                }
            }
            
            switch itemObject {
            case .ship:
                cache.ship[attributeId] = currentValue
            case .character:
                ()
            case .charge(let index):
                if cache.charge[index] != nil {
                    cache.charge[index]?[attributeId] = currentValue
                } else {
                    cache.charge[index] = [attributeId: currentValue]
                }
            case .item(let index):
                if cache.items[index] != nil {
                    cache.items[index]?[attributeId] = currentValue
                } else {
                    cache.items[index] = [attributeId: currentValue]
                }
            case .skill(let index):
                if cache.skills[index] != nil {
                    cache.skills[index]?[attributeId] = currentValue
                } else {
                    cache.skills[index] = [attributeId: currentValue]
                }
            case .structure:
                ()
            case .target:
                ()
            }
        }
        
        return currentValue
    }
    
}
