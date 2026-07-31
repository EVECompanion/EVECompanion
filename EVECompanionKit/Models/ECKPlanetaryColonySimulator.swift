//
//  ECKPlanetaryColonySimulator.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 23.07.26.
//

import Foundation

/// The simulated state of a single pin as of a given point in time.
public struct ECKSimulatedPinState: Hashable, Sendable {
    
    public static let dummy1: ECKSimulatedPinState = {
        return .init(pinId: 1,
                     originalPin: .dummy1,
                     contents: ECKPlanetaryColonyPin.dummy1.contents ?? [],
                     contentVolume: ECKPlanetaryColonyPin.dummy1.contents?.reduce(0, { $0 + $1.volume }) ?? 0,
                     extractedSinceSnapshot: 5)
    }()
    
    public static let dummy2: ECKSimulatedPinState = {
        return .init(pinId: 2,
                     originalPin: .dummy2,
                     contents: ECKPlanetaryColonyPin.dummy2.contents ?? [],
                     contentVolume: ECKPlanetaryColonyPin.dummy2.contents?.reduce(0, { $0 + $1.volume }) ?? 0,
                     extractedSinceSnapshot: 5)
    }()
    
    public static let dummy3: ECKSimulatedPinState = {
        return .init(pinId: 3,
                     originalPin: .dummy3,
                     contents: ECKPlanetaryColonyPin.dummy3.contents ?? [],
                     contentVolume: ECKPlanetaryColonyPin.dummy3.contents?.reduce(0, { $0 + $1.volume }) ?? 0,
                     extractedSinceSnapshot: 5)
    }()
    
    public static let dummy4: ECKSimulatedPinState = {
        return .init(pinId: 4,
                     originalPin: .dummy4,
                     contents: ECKPlanetaryColonyPin.dummy4.contents ?? [],
                     contentVolume: ECKPlanetaryColonyPin.dummy4.contents?.reduce(0, { $0 + $1.volume }) ?? 0,
                     extractedSinceSnapshot: 5)
    }()
    
    public let pinId: Int
    internal let originalPin: ECKPlanetaryColonyPin
    public let contents: [ECKPlanetaryColonyPinContent]
    public let contentVolume: Float
    /// Units of the extractor's product harvested since the colony snapshot
    /// was taken (0 for non-extractor pins). Useful for showing "+X since
    /// last check" even independent of routing/storage assumptions.
    public let extractedSinceSnapshot: Int
    
    public var item: ECKItem {
        return originalPin.item
    }
    
    public var extractorDetails: ECKPlanetaryColonyPinExtractorDetails? {
        return originalPin.extractorDetails
    }
    
    public var extractorValues: [(date: Date, units: Int)] {
        return originalPin.extractorValues
    }
    
    public var schematic: ECKPlanetSchematic? {
        return originalPin.schematic
    }
    
    public var warnings: Set<ECKPlanetaryColonyDetails.Warning> {
        return originalPin.warnings
    }
    
    public var extractorStartTime: Date? {
        return originalPin.extractorStartTime
    }
    
    public var extractorEndTime: Date? {
        return originalPin.extractorEndTime
    }
}
 
/// Result of simulating a whole colony forward to a point in time.
public struct ECKPlanetaryColonySimulationResult {
    public let asOf: Date
    public let pinStates: [Int: ECKSimulatedPinState]
    
    public var pins: [ECKSimulatedPinState] {
        return Array(pinStates.values).sorted(by: { $0.pinId < $1.pinId })
    }
    
    public subscript(pinId: Int) -> ECKSimulatedPinState? {
        return pinStates[pinId]
    }
}
 
public final class ECKPlanetaryColonySimulator {
    
    private let colony: ECKPlanetaryColonyDetails
    
    private var itemCache: [Int: ECKItem] = [:]
    
    public init(colony: ECKPlanetaryColonyDetails, stepInterval: TimeInterval = 300) {
        self.colony = colony
    }
    
    private func item(for typeId: Int) -> ECKItem {
        if let cached = itemCache[typeId] {
            return cached
        }
        let item = ECKItem(typeId: typeId)
        itemCache[typeId] = item
        return item
    }
    
    private func volume(of contents: [Int: Int]) -> Float {
        return contents.reduce(into: Float(0)) { partial, entry in
            partial += Float(entry.value) * (item(for: entry.key).volume ?? 0)
        }
    }
    
    /// Returns the pin's remaining free volume (m3), or `nil` if the pin has
    /// no tracked capacity (i.e. unconstrained -- see callers for how that's
    /// handled). We intentionally do NOT return a large sentinel value like
    /// `.greatestFiniteMagnitude` here: dividing that by a small
    /// `volumePerUnit` at the call sites can overflow to `.infinity`, and
    /// `Int(.infinity)` crashes at runtime. `nil` forces callers to handle
    /// "unconstrained" as its own case instead of relying on float math.
    private func freeCapacity(for pin: ECKPlanetaryColonyPin, currentContents: [Int: Int]) -> Float? {
        // Factory pins in particular typically have no `capacity` attribute
        // at all (see the "not real storages" comment on
        // ECKPlanetaryColonyPin.storageWarnings) -- that's a lack of data,
        // not a real capacity of zero, so we treat it as unconstrained.
        guard let capacity = pin.item.capacity, capacity > 0 else {
            return nil
        }
        return max(0, capacity - volume(of: currentContents))
    }
    
    /// Caps `units` by how many whole units fit into `freeVolume` m3 at
    /// `volumePerUnit` m3 each. Returns `units` unchanged if there's no
    /// tracked capacity (`freeVolume == nil`) or no known per-unit volume.
    /// Also guards against non-finite results, so this can never crash on
    /// the `Int(...)` conversion regardless of input.
    private func capUnits(_ units: Int, byFreeVolume freeVolume: Float?, volumePerUnit: Float) -> Int {
        guard let freeVolume, volumePerUnit > 0 else {
            return units
        }
        let rawCap = freeVolume / volumePerUnit
        guard rawCap.isFinite, rawCap < Float(Int.max) else {
            return units
        }
        return min(units, Int(rawCap))
    }
    
    private func schematic(for pin: ECKPlanetaryColonyPin) -> ECKPlanetSchematic? {
        return pin.schematic ?? pin.factoryDetails?.schematic
    }
    
    public func simulate(snapshotTime: Date, asOf now: Date = Date()) -> ECKPlanetaryColonySimulationResult {
        var ledger: [Int: [Int: Int]] = [:]
        for pin in colony.pins {
            var byType: [Int: Int] = [:]
            for content in pin.contents ?? [] {
                byType[content.item.typeId, default: 0] += content.amount
            }
            ledger[pin.pinId] = byType
        }
        
        var extractedSinceSnapshot: [Int: Int] = [:]
        for pin in colony.pins {
            extractedSinceSnapshot[pin.pinId] = 0
        }
        
        guard snapshotTime < now else {
            return makeResult(from: ledger, extracted: extractedSinceSnapshot, asOf: snapshotTime)
        }
        
        let pinsById = Dictionary(uniqueKeysWithValues: colony.pins.map { ($0.pinId, $0) })
        let routesBySource = Dictionary(grouping: colony.routes, by: \.sourcePinId)
            .mapValues { $0.sorted { $0.routeId < $1.routeId } }
        let routesByDestination = Dictionary(grouping: colony.routes, by: \.destinationPinId)
            .mapValues { $0.sorted { $0.routeId < $1.routeId } }
        let factoryPins = colony.pins
            .filter { $0.pinType == .factory }
            .sorted { $0.pinId < $1.pinId }
        
        var factoryNextCompletion: [Int: Date] = [:]
        for pin in factoryPins {
            guard let schematic = schematic(for: pin), let anchor = pin.lastCycleStart else { continue }
            let completion = anchor.addingTimeInterval(TimeInterval(schematic.cycleTime))
            if completion > snapshotTime {
                factoryNextCompletion[pin.pinId] = completion
            }
        }
        
        let extractorCyclesByPin: [Int: [(end: Date, units: Int, productTypeId: Int)]] = Dictionary(uniqueKeysWithValues: colony.pins.compactMap { pin in
            guard pin.pinType == .extractor,
                  let cycleTime = pin.extractorDetails?.cycleTime,
                  let product = pin.extractorDetails?.product else {
                return nil
            }
            
            let cycles = pin.extractorValues.compactMap { cycle -> (end: Date, units: Int, productTypeId: Int)? in
                let cycleEnd = cycle.date.addingTimeInterval(TimeInterval(cycleTime))
                guard cycleEnd > snapshotTime, cycleEnd <= now else {
                    return nil
                }
                return (end: cycleEnd, units: cycle.units, productTypeId: product.typeId)
            }
            return (pin.pinId, cycles)
        })
        var extractorCycleIndexes = Dictionary(uniqueKeysWithValues: extractorCyclesByPin.map { ($0.key, 0) })
        
        func factoryInputNeed(for pin: ECKPlanetaryColonyPin, typeId: Int) -> Int? {
            guard let schematic = schematic(for: pin),
                  let input = schematic.inputs.first(where: { $0.item.typeId == typeId }) else {
                return nil
            }
            let currentAmount = ledger[pin.pinId]?[typeId] ?? 0
            return max(0, input.quantity - currentAmount)
        }
        
        @discardableResult
        func moveAlongRoute(_ route: ECKPlanetaryColonyRoute, maxUnits: Int) -> Int {
            guard maxUnits > 0,
                  let destination = pinsById[route.destinationPinId] else {
                return 0
            }
            
            let routeLimit = max(0, Int(route.quantity))
            var sourceContents = ledger[route.sourcePinId] ?? [:]
            let available = sourceContents[route.contentTypeId] ?? 0
            var moved = min(maxUnits, routeLimit, available)
            guard moved > 0 else {
                return 0
            }
            
            if destination.pinType == .factory {
                moved = min(moved, factoryInputNeed(for: destination, typeId: route.contentTypeId) ?? 0)
            } else {
                let destContents = ledger[route.destinationPinId] ?? [:]
                let free = freeCapacity(for: destination, currentContents: destContents)
                let volumePerUnit = item(for: route.contentTypeId).volume ?? 0
                moved = capUnits(moved, byFreeVolume: free, volumePerUnit: volumePerUnit)
            }
            guard moved > 0 else {
                return 0
            }
            
            sourceContents[route.contentTypeId, default: 0] -= moved
            if sourceContents[route.contentTypeId] == 0 {
                sourceContents[route.contentTypeId] = nil
            }
            ledger[route.sourcePinId] = sourceContents
            ledger[route.destinationPinId, default: [:]][route.contentTypeId, default: 0] += moved
            return moved
        }
        
        func routeProducedContent(from sourcePinId: Int, typeId: Int, units: Int) {
            var remaining = units
            for route in routesBySource[sourcePinId] ?? [] where route.contentTypeId == typeId {
                let moved = moveAlongRoute(route, maxUnits: remaining)
                remaining -= moved
                if remaining <= 0 {
                    break
                }
            }
        }
        
        func factoryHasAllInputs(_ pin: ECKPlanetaryColonyPin) -> Bool {
            guard let schematic = schematic(for: pin) else {
                return false
            }
            let contents = ledger[pin.pinId] ?? [:]
            return schematic.inputs.allSatisfy { (contents[$0.item.typeId] ?? 0) >= $0.quantity }
        }
        
        func fillFactoryInputs(_ pin: ECKPlanetaryColonyPin) {
            guard let schematic = schematic(for: pin) else {
                return
            }
            
            for input in schematic.inputs {
                var needed = max(0, input.quantity - (ledger[pin.pinId]?[input.item.typeId] ?? 0))
                guard needed > 0 else { continue }
                
                for route in routesByDestination[pin.pinId] ?? [] where route.contentTypeId == input.item.typeId {
                    let moved = moveAlongRoute(route, maxUnits: needed)
                    needed -= moved
                    if needed <= 0 {
                        break
                    }
                }
            }
        }
        
        func consumeFactoryInputs(_ pin: ECKPlanetaryColonyPin) {
            guard let schematic = schematic(for: pin) else {
                return
            }
            var contents = ledger[pin.pinId] ?? [:]
            for input in schematic.inputs {
                contents[input.item.typeId, default: 0] -= input.quantity
                if contents[input.item.typeId] == 0 {
                    contents[input.item.typeId] = nil
                }
            }
            ledger[pin.pinId] = contents
        }
        
        func startReadyFactories(at date: Date) {
            for pin in factoryPins where factoryNextCompletion[pin.pinId] == nil {
                guard let schematic = schematic(for: pin), schematic.cycleTime > 0 else { continue }
                
                fillFactoryInputs(pin)
                guard factoryHasAllInputs(pin) else { continue }
                
                consumeFactoryInputs(pin)
                factoryNextCompletion[pin.pinId] = date.addingTimeInterval(TimeInterval(schematic.cycleTime))
            }
        }
        
        startReadyFactories(at: snapshotTime)
        
        while true {
            var nextEvent: Date?
            
            for (pinId, cycles) in extractorCyclesByPin {
                let index = extractorCycleIndexes[pinId] ?? 0
                guard index < cycles.count else { continue }
                let cycleEnd = cycles[index].end
                if nextEvent == nil || cycleEnd < nextEvent! {
                    nextEvent = cycleEnd
                }
            }
            
            for completion in factoryNextCompletion.values {
                guard completion <= now else { continue }
                if nextEvent == nil || completion < nextEvent! {
                    nextEvent = completion
                }
            }
            
            guard let eventTime = nextEvent, eventTime <= now else { break }
            
            for pinId in extractorCyclesByPin.keys.sorted() {
                guard let cycles = extractorCyclesByPin[pinId] else { continue }
                var index = extractorCycleIndexes[pinId] ?? 0
                
                while index < cycles.count, cycles[index].end == eventTime {
                    let cycle = cycles[index]
                    ledger[pinId, default: [:]][cycle.productTypeId, default: 0] += cycle.units
                    extractedSinceSnapshot[pinId, default: 0] += cycle.units
                    routeProducedContent(from: pinId, typeId: cycle.productTypeId, units: cycle.units)
                    index += 1
                }
                
                extractorCycleIndexes[pinId] = index
            }
            
            for pin in factoryPins where factoryNextCompletion[pin.pinId] == eventTime {
                guard let schematic = schematic(for: pin) else { continue }
                
                ledger[pin.pinId, default: [:]][schematic.output.item.typeId, default: 0] += schematic.output.quantity
                routeProducedContent(from: pin.pinId, typeId: schematic.output.item.typeId, units: schematic.output.quantity)
                factoryNextCompletion[pin.pinId] = nil
            }
            
            startReadyFactories(at: eventTime)
        }
        
        return makeResult(from: ledger, extracted: extractedSinceSnapshot, asOf: now)
    }
    
    private func makeResult(from ledger: [Int: [Int: Int]], extracted: [Int: Int], asOf: Date) -> ECKPlanetaryColonySimulationResult {
        var states: [Int: ECKSimulatedPinState] = [:]
        for pin in colony.pins {
            let byType = ledger[pin.pinId] ?? [:]
            let contents = byType.map { ECKPlanetaryColonyPinContent(item: item(for: $0.key), amount: $0.value) }
            states[pin.pinId] = ECKSimulatedPinState(pinId: pin.pinId,
                                                     originalPin: pin,
                                                     contents: contents.filter({ $0.amount > 0 }),
                                                     contentVolume: volume(of: byType),
                                                     extractedSinceSnapshot: extracted[pin.pinId] ?? 0)
        }
        return ECKPlanetaryColonySimulationResult(asOf: asOf, pinStates: states)
    }
    
}
 
public extension ECKPlanetaryColonyDetails {
    
    func simulated(since snapshotTime: Date, asOf now: Date = Date()) -> ECKPlanetaryColonySimulationResult {
        return ECKPlanetaryColonySimulator(colony: self).simulate(snapshotTime: snapshotTime, asOf: now)
    }
    
    func simulated(using summary: ECKPlanetaryColony, asOf now: Date = Date()) -> ECKPlanetaryColonySimulationResult {
        return simulated(since: summary.lastUpdate, asOf: now)
    }
    
}
