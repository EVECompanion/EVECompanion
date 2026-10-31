//
//  ECKFittingCapacitorTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 29.10.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKFittingCapacitorTests {

    @Test
    func capacitorStatusReportsStableAndUnstableFits() throws {
        let stable = Self.fitting(capacitorUse: 1, state: .active)
        let stableStatus = try #require(stable.capacitorStability)
        #expect(stableStatus.isStable)
        #expect(stableStatus.timeToEmpty == nil)

        let unstable = Self.fitting(capacitorUse: 10, state: .active)
        let unstableStatus = try #require(unstable.capacitorStability)
        #expect(unstableStatus.isStable == false)
        #expect(unstableStatus.timeToEmpty != nil)
        #expect((unstableStatus.timeToEmpty ?? 0) > 0)

        let unstableWeapon = Self.fitting(capacitorUse: 10,
                                          state: .active,
                                          cycleAttributeId: ECKCharacterFitting.attributeRoFId)
        let weaponStatus = try #require(unstableWeapon.capacitorStability)
        #expect(weaponStatus.isStable == false)
        #expect((weaponStatus.timeToEmpty ?? 0) > 0)
    }

    @Test
    func capacitorDrainOnlyAppliesToRunningModules() throws {
        let online = Self.fitting(capacitorUse: 10, state: .online)
        let onlineStatus = try #require(online.capacitorStability)
        #expect(onlineStatus.isStable)
        #expect(onlineStatus.timeToEmpty == nil)

        let overloaded = Self.fitting(capacitorUse: 10, state: .overload)
        let overloadedStatus = try #require(overloaded.capacitorStability)
        #expect(overloadedStatus.isStable == false)
        #expect((overloadedStatus.timeToEmpty ?? 0) > 0)
    }

    @Test
    func offlineModulesDoNotChangeCapacitorStabilityOrAdjacentStats() throws {
        let fitting = Self.fitting(capacitorUse: 10, state: .offline)
        let powerLoad = ECKCharacterFitting.FittingAttribute(id: ECKCharacterFitting.attributePowerLoadId,
                                                             defaultValue: 42)
        powerLoad.value = 42
        fitting.ship.attributes[ECKCharacterFitting.attributePowerLoadId] = powerLoad

        let status = try #require(fitting.capacitorStability)
        #expect(status.isStable)
        #expect(status.timeToEmpty == nil)
        #expect(fitting.powerLoad == 42)
    }

    private static func fitting(capacitorUse: Float,
                                state: ECKDogmaEffect.Category,
                                cycleAttributeId: Int = ECKCharacterFitting.attributeActivationTimeId) -> ECKCharacterFitting {
        let module = ECKCharacterFittingItem(flag: .HiSlot0,
                                             quantity: 1,
                                             item: item(typeId: 3, name: "Test Module"))
        module.state = state
        module.attributes[ECKCharacterFitting.attributeCapacitorUseId] = .init(id: ECKCharacterFitting.attributeCapacitorUseId,
                                                                               defaultValue: capacitorUse)
        module.attributes[cycleAttributeId] = .init(id: cycleAttributeId, defaultValue: 1_000)
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [module],
                                          name: "Capacitor Test",
                                          ship: item(typeId: 1, name: "Test Ship"))
        fitting.ship.attributes[ECKCharacterFitting.attributeCapacitorCapacityId] = .init(id: ECKCharacterFitting.attributeCapacitorCapacityId,
                                                                                          defaultValue: 1_000)
        fitting.ship.attributes[ECKCharacterFitting.attributeCapacitorRechargeTimeId] = .init(id: ECKCharacterFitting.attributeCapacitorRechargeTimeId,
                                                                                              defaultValue: 1_000_000)
        return fitting
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
