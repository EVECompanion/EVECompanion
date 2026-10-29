//
//  ECKFittingBoosterTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 29.10.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKFittingBoosterTests {

    @Test
    func fittingItemSourcesAffectShipAttributesWithoutChangingUnrelatedAttributes() async throws {
        let booster = ECKCharacterFittingItem(flag: .BoosterBay,
                                              quantity: 1,
                                              item: Self.item(typeId: 2, name: "Synth Booster"))
        let module = ECKCharacterFittingItem(flag: .HiSlot0,
                                             quantity: 1,
                                             item: Self.item(typeId: 3, name: "Test Module"))
        let charge = ECKCharacterFittingItem(flag: .HiSlot0,
                                             quantity: 1,
                                             item: Self.item(typeId: 4, name: "Test Charge"))
        module.charge = charge
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [booster, module],
                                          name: "Booster Calculation",
                                          ship: Self.item(typeId: 1, name: "Test Ship"))
        let boosterAttribute = ECKCharacterFitting.FittingAttribute(id: 100, defaultValue: 5)
        boosterAttribute.value = 5
        booster.attributes[100] = boosterAttribute
        let moduleAttribute = ECKCharacterFitting.FittingAttribute(id: 101, defaultValue: 7)
        moduleAttribute.value = 7
        module.attributes[101] = moduleAttribute
        let chargeAttribute = ECKCharacterFitting.FittingAttribute(id: 102, defaultValue: 11)
        chargeAttribute.value = 11
        charge.attributes[102] = chargeAttribute

        let modifiedAttribute = ECKCharacterFitting.FittingAttribute(id: 200, defaultValue: 10)
        modifiedAttribute.effects.append(.init(effectId: 1,
                                               operation: .modAdd,
                                               penalty: false,
                                               source: .booster(.init(booster)),
                                               sourceCategory: .online,
                                               sourceAttributeId: 100))
        modifiedAttribute.effects.append(.init(effectId: 2,
                                               operation: .modAdd,
                                               penalty: false,
                                               source: .item(.init(module)),
                                               sourceCategory: .online,
                                               sourceAttributeId: 101))
        modifiedAttribute.effects.append(.init(effectId: 3,
                                               operation: .modAdd,
                                               penalty: false,
                                               source: .charge(parent: .init(module), item: .init(charge)),
                                               sourceCategory: .online,
                                               sourceAttributeId: 102))
        fitting.ship.attributes[200] = modifiedAttribute
        fitting.ship.attributes[201] = .init(id: 201, defaultValue: 30)

        await fitting.pass3()

        #expect(fitting.ship.attributes[200]?.value == Float(33))
        #expect(fitting.ship.attributes[201]?.value == Float(30))
    }

    @Test
    func fittingRetainsBoosterAndCargoItemsWhenEncoded() throws {
        let booster = ECKCharacterFittingItem(flag: .BoosterBay,
                                              quantity: 1,
                                              item: Self.item(typeId: 2, name: "Synth Booster"))
        let cargo = ECKCharacterFittingItem(flag: .Cargo,
                                            quantity: 3,
                                            item: Self.item(typeId: 3, name: "Cargo Item"))
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [booster, cargo],
                                          name: "Booster Test",
                                          ship: Self.item(typeId: 1, name: "Test Ship"))

        #expect(fitting.boosters.map(\.item.name) == ["Synth Booster"])
        #expect(fitting.cargoItems.map(\.item.name) == ["Cargo Item"])

        let data = try JSONEncoder().encode(fitting)
        let serialized = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let serializedBoosters = try #require(serialized["boosters"] as? [[String: Any]])
        let serializedCargo = try #require(serialized["cargoItems"] as? [[String: Any]])

        #expect(serializedBoosters.first?["type_id"] as? Int == 2)
        #expect(serializedCargo.first?["type_id"] as? Int == 3)
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
