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
        var objects: [ObjectIdentifier: [Int: Float]] = [:]
        var target: [Int: Float] = [:]
        var character: [Int: Float] = [:]
        var structure: [Int: Float] = [:]
        
        init() { }
    }
    
    internal func pass3() async {
        let cache = AttributesCache()
        let fittedItems = items
        let fittedBoosters = boosters
        let fittedSkills = skills
        
        for skill in fittedSkills {
            if let skillLevel = skill.attributes[Self.attributeSkillLevelId]?.baseValue {
                cache.objects[ObjectIdentifier(skill)] = [Self.attributeSkillLevelId: skillLevel]
            }
        }
        
        await calculateValues(item: ship, ship: ship, itemObject: .ship, cache: cache)
        await calculateValues(item: structure, ship: ship, itemObject: .structure, cache: cache)
        await calculateValues(item: target, ship: ship, itemObject: .target, cache: cache)
        await calculateValues(item: character, ship: ship, itemObject: .character, cache: cache)
        for booster in fittedBoosters {
            await calculateValues(item: booster, ship: ship, itemObject: .booster(.init(booster)), cache: cache)
        }
        for item in fittedItems {
            await calculateValues(item: item, ship: ship, itemObject: .item(.init(item)), cache: cache)
            if let charge = item.charge {
                await calculateValues(item: charge,
                                      ship: ship,
                                      itemObject: .charge(parent: .init(item), item: .init(charge)),
                                      cache: cache)
            }
        }
        
        for skill in fittedSkills {
            await calculateValues(item: skill,
                                  ship: ship,
                                  itemObject: .skill(.init(skill)),
                                  cache: cache)
        }
        
        for booster in fittedBoosters {
            await storeCachedValues(for: booster, cache: cache.objects[ObjectIdentifier(booster)] ?? [:])
        }
        await storeCachedValues(for: ship, cache: cache.ship)
        await storeCachedValues(for: structure, cache: cache.structure)
        await storeCachedValues(for: target, cache: cache.target)
        for item in fittedItems {
            await storeCachedValues(for: item, cache: cache.objects[ObjectIdentifier(item)] ?? [:])
            if let charge = item.charge {
                await storeCachedValues(for: charge, cache: cache.objects[ObjectIdentifier(charge)] ?? [:])
            }
        }
        
        for skill in fittedSkills {
            await storeCachedValues(for: skill, cache: cache.objects[ObjectIdentifier(skill)] ?? [:])
        }
    }
    
    private func calculateValues(item: ECKCharacterFittingItem,
                                 ship: ECKCharacterFittingItem,
                                 itemObject: ECKCharacterFitting.ItemObject,
                                 cache: AttributesCache) async {
        for attribute in item.attributes.values {
            await calculateValue(for: attribute,
                                 ship: ship,
                                 attributeId: attribute.id,
                                 itemObject: itemObject,
                                 cache: cache)
        }
    }
    
    private func storeCachedValues(for item: ECKCharacterFittingItem, cache: [Int: Float]) async {
        for (attributeId, value) in cache {
            if let attribute = item.attributes[attributeId] {
                attribute.value = value
            } else if let defaultValue = await ECKAttributeDefaultValueCache.shared.getDefaultValue(for: attributeId) {
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
                                cache: AttributesCache) async -> Float {
        
        // Keep dogma operations in Double precision: `1 / mass - 1` rounds to -1 in Float for ship-scale masses.
        var currentValue = Double(attribute.baseValue)
        
        if let value = attribute.value {
            return value
        }
        
        var cacheValue: Float?
        
        switch itemObject {
        case .ship:
            cacheValue = cache.ship[attributeId]
        case .character:
            cacheValue = cache.character[attributeId]
        case .charge(_, let reference), .booster(let reference), .item(let reference), .skill(let reference):
            cacheValue = cache.objects[reference.identifier]?[attributeId]
        case .structure:
            cacheValue = cache.structure[attributeId]
        case .target:
            cacheValue = cache.target[attributeId]
        }
        
        if let cacheValue {
            return cacheValue
        }
        
        for operation in ECKCharacterFitting.ModifierOperation.allCases {
            var nonPenaltyValues: [Double] = []
            var positivePenaltyValues: [Double] = []
            var negativePenaltyValues: [Double] = []
            
            for effect in attribute.effects {
                guard effect.operation == operation else {
                    continue
                }
                
                let source: ECKCharacterFittingItem
                
                switch effect.source {
                case .ship:
                    source = ship
                case .character:
                    source = character
                case .charge(_, let reference), .booster(let reference), .item(let reference), .skill(let reference):
                    guard let item = reference.item else { continue }
                    source = item
                case .structure:
                    source = self.structure
                case .target:
                    source = self.target
                }
                
                if effect.sourceCategory.isEnabled(in: source.state) == false {
                    continue
                }
                
                var sourceValue: Double
                
                if let sourceAttribute = source.attributes[effect.sourceAttributeId] {
                    sourceValue = Double(await calculateValue(for: sourceAttribute,
                                                              ship: ship,
                                                              attributeId: effect.sourceAttributeId,
                                                              itemObject: effect.source,
                                                              cache: cache))
                } else {
                    guard let defaultValue = await ECKAttributeDefaultValueCache.shared.getDefaultValue(for: effect.sourceAttributeId) else {
                        continue
                    }
                    
                    sourceValue = Double(defaultValue)
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
                    currentValue *= 1.0 + value * exp(-pow(Double(index) / 2.67, 2.0))
                }
                
                negativePenaltyValues.sort()
                
                for (index, value) in negativePenaltyValues.enumerated() {
                    currentValue *= 1.0 + value * exp(-pow(Double(index) / 2.67, 2.0))
                }
                
            case .modAdd,
                 .modSub:
                for value in nonPenaltyValues {
                    currentValue += value
                }
            }
        }
        
        let result = Float(currentValue)

        switch itemObject {
        case .ship:
            cache.ship[attributeId] = result
        case .character:
            cache.character[attributeId] = result
        case .charge(_, let reference), .booster(let reference), .item(let reference), .skill(let reference):
            cache.objects[reference.identifier, default: [:]][attributeId] = result
        case .structure:
            cache.structure[attributeId] = result
        case .target:
            cache.target[attributeId] = result
        }
        
        return result
    }
    
}
