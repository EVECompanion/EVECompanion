//
//  ECKEFTFormatTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 27.10.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKEFTFormatTests {

    @Test
    func exportsModulesChargesDronesAndCargo() {
        let ship = Self.item(typeId: 1, name: "Test Ship")
        let gun = Self.item(typeId: 2, name: "Test Gun")
        let ammo = Self.item(typeId: 3, name: "Test Charge")
        let drone = Self.item(typeId: 4, name: "Test Drone")
        let fittedGun = ECKCharacterFittingItem(flag: .HiSlot0, quantity: 1, item: gun)
        fittedGun.charge = ECKCharacterFittingItem(flag: .HiSlot0, quantity: 1, item: ammo)
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [fittedGun,
                                                  .init(flag: .DroneBay, quantity: 5, item: drone),
                                                  .init(flag: .Cargo, quantity: 42, item: ammo)],
                                          name: "Export Test",
                                          ship: ship)

        let eft = ECKEFTFormat.export(fitting)

        #expect(eft.contains("[Test Ship, Export Test]"))
        #expect(eft.contains("Test Gun, Test Charge"))
        #expect(eft.contains("Test Drone x5"))
        #expect(eft.contains("Test Charge x42"))
    }

    @Test
    func importsOfflineModulesChargesDronesAndCargo() throws {
        let items = Self.items()
        let text = """
        [Test Ship, Import Test]
        Test Gun /offline, Test Charge

        Test Drone x5


        Test Cargo x42
        """.replacingOccurrences(of: "\n", with: "\r\n")

        let fitting = try Self.importFitting(text, items: items)
        let gun = try #require(fitting.highSlotModules.first)
        let drone = try #require(fitting.drones.first)
        let cargo = try #require(fitting.cargoItems.first)

        #expect(fitting.name == "Import Test")
        #expect(gun.item.name == "Test Gun")
        #expect(gun.state == .offline)
        #expect(gun.charge?.item.name == "Test Charge")
        #expect(drone.quantity == 5)
        #expect(cargo.item.name == "Test Cargo")
        #expect(cargo.quantity == 42)
    }

    @Test
    func importsEveryFittedSlotCategory() throws {
        let items = Self.items()
        let text = """
        [Test Ship, Slot Test]
        Test Low

        Test Mid

        Test Gun

        Test Rig

        Test Subsystem
        """

        let fitting = try Self.importFitting(text, items: items)

        #expect(fitting.lowSlotModules.map(\.item.name) == ["Test Low"])
        #expect(fitting.midSlotModules.map(\.item.name) == ["Test Mid"])
        #expect(fitting.highSlotModules.map(\.item.name) == ["Test Gun"])
        #expect(fitting.rigs.map(\.item.name) == ["Test Rig"])
        #expect(fitting.subsystems.map(\.item.name) == ["Test Subsystem"])
    }

    @Test
    func importsFightersAndUsesShipNameWhenFitNameIsMissing() throws {
        let items = Self.items()
        let fitting = try Self.importFitting("[Test Ship]\nTest Fighter x3", items: items)
        let fighter = try #require(fitting.fighters.first)

        #expect(fitting.name == "Test Ship")
        #expect(fighter.quantity == 3)
        #expect(fighter.flag == .FighterTube0)
    }

    @Test
    func rejectsMalformedHeadersAndUnknownTypes() {
        #expect(throws: ECKEFTFormat.ImportError.invalidHeader) {
            try Self.importFitting("Test Gun", items: Self.items())
        }
        #expect(throws: ECKEFTFormat.ImportError.unknownItem("Missing Ship")) {
            try Self.importFitting("[Missing Ship, Fit]", items: Self.items())
        }
        #expect(throws: ECKEFTFormat.ImportError.unknownItem("Missing Module")) {
            try Self.importFitting("[Test Ship, Fit]\nMissing Module", items: Self.items())
        }
    }

    @Test
    func exportsOfflineSuffixBeforeChargeAndOmitsSingleUnitCount() {
        let gun = Self.item(typeId: 2, name: "Test Gun")
        let charge = Self.item(typeId: 3, name: "Test Charge")
        let module = ECKCharacterFittingItem(flag: .HiSlot0, quantity: 1, item: gun)
        module.charge = ECKCharacterFittingItem(flag: .HiSlot0, quantity: 1, item: charge)
        module.state = .offline
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [module],
                                          name: "Offline",
                                          ship: Self.item(typeId: 1, name: "Test Ship"))

        #expect(ECKEFTFormat.export(fitting) == "[Test Ship, Offline]\n\nTest Gun /offline, Test Charge")
    }

    @Test
    func emptyFitExportsOnlyItsHeader() {
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [],
                                          name: "Empty",
                                          ship: Self.item(typeId: 1, name: "Test Ship"))

        #expect(ECKEFTFormat.export(fitting) == "[Test Ship, Empty]")
    }

    private static func item(typeId: Int, name: String) -> ECKItem {
        ECKItem(itemData: (typeId: typeId,
                           name: name,
                           description: nil,
                           mass: nil,
                           volume: 0,
                           capacity: nil,
                           radius: nil,
                           iconId: nil))
    }

    private static func items() -> [String: ECKItem] {
        [
            "Test Ship": item(typeId: 1, name: "Test Ship"),
            "Test Gun": item(typeId: 2, name: "Test Gun"),
            "Test Charge": item(typeId: 3, name: "Test Charge"),
            "Test Drone": item(typeId: 4, name: "Test Drone"),
            "Test Fighter": item(typeId: 5, name: "Test Fighter"),
            "Test Low": item(typeId: 6, name: "Test Low"),
            "Test Mid": item(typeId: 7, name: "Test Mid"),
            "Test Rig": item(typeId: 8, name: "Test Rig"),
            "Test Subsystem": item(typeId: 9, name: "Test Subsystem"),
            "Test Cargo": item(typeId: 10, name: "Test Cargo")
        ]
    }

    private static func importFitting(_ text: String,
                                      items: [String: ECKItem]) throws -> ECKCharacterFitting {
        try ECKEFTFormat.importFitting(from: text,
                                       resolveItem: { items[$0] },
                                       classifyItem: { item in
            switch item.typeId {
            case 2: return .module(.high)
            case 4: return .drone
            case 5: return .fighter
            case 6: return .module(.low)
            case 7: return .module(.mid)
            case 8: return .module(.rig)
            case 9: return .module(.subsystem)
            default: return .other
            }
        })
    }
}
