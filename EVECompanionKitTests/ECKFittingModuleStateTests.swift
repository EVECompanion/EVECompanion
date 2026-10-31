//
//  ECKFittingModuleStateTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 29.10.26.
//

import Testing
@testable import EVECompanionKit

struct ECKFittingModuleStateTests {

    @Test
    func dogmaEffectCategoriesFollowModuleStateSemantics() {
        #expect(ECKDogmaEffect.Category.online.isEnabled(in: .online))
        #expect(ECKDogmaEffect.Category.active.isEnabled(in: .online) == false)
        #expect(ECKDogmaEffect.Category.online.isEnabled(in: .active))
        #expect(ECKDogmaEffect.Category.active.isEnabled(in: .active))
        #expect(ECKDogmaEffect.Category.overload.isEnabled(in: .active) == false)
        #expect(ECKDogmaEffect.Category.overload.isEnabled(in: .overload))

        // Target effects are active-module effects, while system effects stay outside module state filtering.
        #expect(ECKDogmaEffect.Category.target.isEnabled(in: .active))
        #expect(ECKDogmaEffect.Category.target.isEnabled(in: .online) == false)
        #expect(ECKDogmaEffect.Category.system.isEnabled(in: .overload) == false)
        #expect(ECKDogmaEffect.Category.offline.isEnabled(in: .offline))
        #expect(ECKDogmaEffect.Category.offline.isEnabled(in: .online) == false)
    }

    @Test
    func selectableModuleStatesUseModuleStateOrder() {
        let module = ECKCharacterFittingItem(flag: .HiSlot0,
                                             quantity: 1,
                                             item: Self.item(typeId: 3, name: "Test Module"))
        module.maxState = .active
        #expect(module.userSettableStates == [.offline, .online, .active])

        module.maxState = .online
        #expect(module.userSettableStates == [.offline, .online])
    }

    @Test
    func activeAndOverloadedPropulsionEffectsChangeShipVelocity() async throws {
        let onlineFit = Self.propulsionFitting(state: .online)
        await onlineFit.pass3()
        #expect(onlineFit.maxVelocity == 100)

        let activeFit = Self.propulsionFitting(state: .active)
        await activeFit.pass3()
        let activeVelocity = try #require(activeFit.maxVelocity)
        #expect(abs(activeVelocity - 610) < 0.01)

        let overloadedFit = Self.propulsionFitting(state: .overload)
        await overloadedFit.pass3()
        let overloadedVelocity = try #require(overloadedFit.maxVelocity)
        #expect(abs(overloadedVelocity - 865) < 0.01)
    }

    private static func propulsionFitting(state: ECKDogmaEffect.Category) -> ECKCharacterFitting {
        let module = ECKCharacterFittingItem(flag: .MedSlot0,
                                             quantity: 1,
                                             item: item(typeId: 3, name: "Test Microwarpdrive"))
        module.state = state
        module.attributes[20] = attribute(20, 510)
        module.attributes[567] = attribute(567, 150_000_000)
        module.attributes[796] = attribute(796, 50_000_000)
        module.attributes[1223] = attribute(1223, 50)
        module.attributes[20]?.value = nil
        module.attributes[20]?.effects.append(.init(effectId: 3175,
                                                     operation: .postPercent,
                                                     penalty: false,
                                                     source: .item(.init(module)),
                                                     sourceCategory: .overload,
                                                     sourceAttributeId: 1223))

        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [module],
                                          name: "Propulsion State Test",
                                          ship: item(typeId: 1, name: "Test Ship"))

        let mass = attribute(4, 100_000_000)
        mass.value = nil
        mass.effects.append(.init(effectId: 6730,
                                  operation: .modAdd,
                                  penalty: false,
                                  source: .item(.init(module)),
                                  sourceCategory: .active,
                                  sourceAttributeId: 796))
        fitting.ship.attributes[4] = mass

        let velocityBoost = ECKCharacterFitting.FittingAttribute(id: -1, defaultValue: 0)
        velocityBoost.effects.append(.init(effectId: 6730,
                                           operation: .modAdd,
                                           penalty: false,
                                           source: .item(.init(module)),
                                           sourceCategory: .active,
                                           sourceAttributeId: 567))
        velocityBoost.effects.append(.init(effectId: 6730,
                                           operation: .postMul,
                                           penalty: false,
                                           source: .item(.init(module)),
                                           sourceCategory: .active,
                                           sourceAttributeId: 20))
        velocityBoost.effects.append(.init(effectId: -1,
                                           operation: .postDiv,
                                           penalty: false,
                                           source: .ship,
                                           sourceCategory: .passive,
                                           sourceAttributeId: 4))
        fitting.ship.attributes[-1] = velocityBoost

        let maxVelocity = attribute(37, 100)
        maxVelocity.value = nil
        maxVelocity.effects.append(.init(effectId: -1,
                                         operation: .postPercent,
                                         penalty: false,
                                         source: .ship,
                                         sourceCategory: .passive,
                                         sourceAttributeId: -1))
        fitting.ship.attributes[37] = maxVelocity
        return fitting
    }

    private static func attribute(_ id: Int, _ value: Float) -> ECKCharacterFitting.FittingAttribute {
        let attribute = ECKCharacterFitting.FittingAttribute(id: id, defaultValue: value)
        attribute.value = value
        return attribute
    }

    private static func item(typeId: Int, name: String) -> ECKItem {
        ECKItem(itemData: (typeId: typeId,
                           name: name,
                           description: nil,
                           mass: nil,
                           volume: nil,
                           capacity: nil,
                           radius: nil,
                           iconId: nil))
    }
}
