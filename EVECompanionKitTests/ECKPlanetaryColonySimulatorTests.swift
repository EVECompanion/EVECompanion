//
//  ECKPlanetaryColonySimulatorTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 31.07.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKPlanetaryColonySimulatorTests {

    @Test
    func routesFactoryOutputBeforeStartingDownstreamFactoryCycle() throws {
        let snapshotTime = try #require(Self.date(hour: 0, minute: 0))
        let asOf = try #require(Self.date(hour: 1, minute: 30))
        let raw = Self.item(typeId: 9001, name: "Raw", volume: 1)
        let processed = Self.item(typeId: 9002, name: "Processed", volume: 1)
        let final = Self.item(typeId: 9003, name: "Final", volume: 1)
        let storageItem = Self.item(typeId: 9010, name: "Storage", capacity: 1_000)
        let factoryItem = Self.item(typeId: 9011, name: "Factory")
        let firstSchematic = Self.schematic(id: 1,
                                            cycleTime: 1_800,
                                            inputs: [(raw, 10)],
                                            output: (processed, 1))
        let secondSchematic = Self.schematic(id: 2,
                                             cycleTime: 3_600,
                                             inputs: [(processed, 1)],
                                             output: (final, 1))
        let storage = Self.pin(id: 1,
                               contents: [],
                               schematic: nil,
                               item: storageItem)
        let firstFactory = Self.pin(id: 2,
                                    contents: [],
                                    lastCycleStart: snapshotTime,
                                    schematic: firstSchematic,
                                    item: factoryItem)
        let secondFactory = Self.pin(id: 3,
                                     contents: [],
                                     schematic: secondSchematic,
                                     item: factoryItem)
        let colony = ECKPlanetaryColonyDetails(links: [],
                                               pins: [storage, firstFactory, secondFactory],
                                               routes: [
                                                   Self.route(id: 1,
                                                              typeId: processed.typeId,
                                                              quantity: 1,
                                                              source: firstFactory.pinId,
                                                              destination: storage.pinId),
                                                   Self.route(id: 2,
                                                              typeId: processed.typeId,
                                                              quantity: 1,
                                                              source: storage.pinId,
                                                              destination: secondFactory.pinId)
                                               ])

        let result = colony.simulated(since: snapshotTime, asOf: asOf)

        #expect(Self.amount(of: final.typeId, in: result[secondFactory.pinId]) == 1)
        #expect(Self.amount(of: processed.typeId, in: result[storage.pinId]) == 0)
    }

    @Test
    func routedFactoryInputsDoNotCompleteBeforeCycleTimeElapsed() throws {
        let snapshotTime = try #require(Self.date(hour: 0, minute: 0))
        let asOf = try #require(Self.date(hour: 0, minute: 29))
        let raw = Self.item(typeId: 9001, name: "Raw", volume: 1)
        let processed = Self.item(typeId: 9002, name: "Processed", volume: 1)
        let storageItem = Self.item(typeId: 9010, name: "Storage", capacity: 1_000)
        let factoryItem = Self.item(typeId: 9011, name: "Factory")
        let schematic = Self.schematic(id: 1,
                                       cycleTime: 1_800,
                                       inputs: [(raw, 10)],
                                       output: (processed, 1))
        let storage = Self.pin(id: 1,
                               contents: [.init(item: raw, amount: 10)],
                               schematic: nil,
                               item: storageItem)
        let factory = Self.pin(id: 2,
                               contents: [],
                               schematic: schematic,
                               item: factoryItem)
        let colony = ECKPlanetaryColonyDetails(links: [],
                                               pins: [storage, factory],
                                               routes: [
                                                   Self.route(id: 1,
                                                              typeId: raw.typeId,
                                                              quantity: 10,
                                                              source: storage.pinId,
                                                              destination: factory.pinId)
                                               ])

        let result = colony.simulated(since: snapshotTime, asOf: asOf)

        #expect(Self.amount(of: processed.typeId, in: result[factory.pinId]) == 0)
        #expect(Self.amount(of: raw.typeId, in: result[storage.pinId]) == 0)
    }

    private static func date(hour: Int, minute: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: .init(year: 2026,
                                         month: 7,
                                         day: 31,
                                         hour: hour,
                                         minute: minute))
    }

    private static func item(typeId: Int,
                             name: String,
                             volume: Float? = nil,
                             capacity: Float? = nil) -> ECKItem {
        ECKItem(itemData: (typeId: typeId,
                           name: name,
                           description: nil,
                           mass: nil,
                           volume: volume,
                           capacity: capacity,
                           radius: nil,
                           iconId: nil))
    }

    private static func schematic(id: Int,
                                  cycleTime: Int,
                                  inputs: [(item: ECKItem, quantity: Int)],
                                  output: (item: ECKItem, quantity: Int)) -> ECKPlanetSchematic {
        let inputData = inputs.map { input in
            (typeId: input.item.typeId, quantity: input.quantity, isInput: true)
        }
        let outputData = (typeId: output.item.typeId, quantity: output.quantity, isInput: false)
        return ECKPlanetSchematic(schematicId: id,
                                  data: (cycleTime: cycleTime, inouts: inputData + [outputData]))
    }

    private static func pin(id: Int,
                            contents: [ECKPlanetaryColonyPinContent],
                            lastCycleStart: Date? = nil,
                            schematic: ECKPlanetSchematic?,
                            item: ECKItem) -> ECKPlanetaryColonyPin {
        ECKPlanetaryColonyPin(contents: contents,
                              expiryTime: nil,
                              extractorDetails: nil,
                              factoryDetails: nil,
                              installTime: nil,
                              lastCycleStart: lastCycleStart,
                              pinId: id,
                              schematic: schematic,
                              item: item)
    }

    private static func route(id: Int,
                              typeId: Int,
                              quantity: Float,
                              source: Int,
                              destination: Int) -> ECKPlanetaryColonyRoute {
        ECKPlanetaryColonyRoute(contentTypeId: typeId,
                                destinationPinId: destination,
                                quantity: quantity,
                                routeId: id,
                                sourcePinId: source,
                                waypoints: nil)
    }

    private static func amount(of typeId: Int, in pinState: ECKSimulatedPinState?) -> Int {
        return pinState?.contents.first(where: { $0.item.typeId == typeId })?.amount ?? 0
    }

}
