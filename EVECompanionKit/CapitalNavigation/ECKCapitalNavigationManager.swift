//
//  ECKCapitalNavigationManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 10.03.25.
//

import Foundation
public import Combine
public import SwiftUI

public enum ECKCapitalJumpRangeSelector {

    public static func systemIdsInRange(from originSystemId: Int,
                                        jumpDistances: [Int: [Int: Double]],
                                        jumpRange: Double,
                                        excluding excludedSystemIds: Set<Int> = []) -> [Int] {
        let candidates = jumpDistances[originSystemId] ?? [:]

        return candidates
            .filter { systemId, distance in
                distance <= jumpRange && excludedSystemIds.contains(systemId) == false
            }
            .map(\.key)
            .sorted()
    }

}

public enum ECKCapitalJumpMapOverlay {

    public typealias RouteSegment = (startSystemId: Int, destinationSystemId: Int)

    public struct StaticRoutePresentation: Equatable {
        public let selectableSystemIds: Set<Int>
        public let highlightedSystemIds: Set<Int>
        public let jumpRouteSystemIds: [Int]
        public let initialFocusSystemId: Int?
    }

    public static func routeSegments(systemIds: [Int]) -> [RouteSegment] {
        zip(systemIds.dropLast(), systemIds.dropFirst()).map { routeStep in
            (startSystemId: routeStep.0, destinationSystemId: routeStep.1)
        }
    }

    public static func highlightedRouteSystemIds(systemIds: [Int]) -> Set<Int> {
        Set(systemIds)
    }

    public static func focusSystemIds(highlightedSystemIds: Set<Int>,
                                      replacementSystemId: Int?) -> Set<Int> {
        var systemIds = highlightedSystemIds
        if let replacementSystemId {
            systemIds.insert(replacementSystemId)
        }

        return systemIds
    }

    public static func staticRoutePresentation(systemIds: [Int]) -> StaticRoutePresentation? {
        guard systemIds.count >= 2 else {
            return nil
        }

        return StaticRoutePresentation(
            selectableSystemIds: [],
            highlightedSystemIds: highlightedRouteSystemIds(systemIds: systemIds),
            jumpRouteSystemIds: systemIds,
            initialFocusSystemId: systemIds.first
        )
    }

    public static func targetScaleToFit(normalizedRectSize: CGSize,
                                        viewportSize: CGSize,
                                        padding: CGFloat,
                                        minimumScale: CGFloat) -> CGFloat {
        guard viewportSize.width > 0,
              viewportSize.height > 0 else {
            return 1
        }

        let widthScale = max(normalizedRectSize.width * padding / viewportSize.width, minimumScale)
        let heightScale = max(normalizedRectSize.height * padding / viewportSize.height, minimumScale)
        return max(widthScale, heightScale)
    }

}

@MainActor
public class ECKCapitalNavigationManager: ObservableObject {
    
    @AppStorage("CapitalNavigation.JDC") public var jdcSkillLevel: Int = 5 {
        didSet {
            self.reloadRoute()
        }
    }
    
    @AppStorage("CapitalNavigation.JFC") public var jfcSkillLevel: Int = 4 {
        didSet {
            self.reloadRoute()
        }
    }
    
    @AppStorage("CapitalNavigation.JFSkill") public var jumpFreighterSkillLevel: Int = 4 {
        didSet {
            self.reloadRoute()
        }
    }
    
    public let ships: [(groupName: String, ships: [ECKJumpCapableShip])]
    @Published public var selectedShip: ECKJumpCapableShip? {
        didSet {
            self.reloadRoute()
        }
    }
    
    public var jumpRange: Double? {
        guard let selectedShip else {
            return nil
        }
        
        return selectedShip.baseJumpRange + (0.2 * Double(jdcSkillLevel)) * selectedShip.baseJumpRange
    }
    
    @Published public var selectedDestinationSystems: [ECKCapitalJumpRoute.SystemEntry] = [] {
        didSet {
            self.reloadRoute()
        }
    }
    
    @Published public var selectedAvoidanceSystems: [ECKCapitalJumpRoute.SystemEntry] = [] {
        didSet {
            self.reloadRoute()
        }
    }
    
    @Published public var route: ECKCapitalJumpRoute?
    @Published public var isRouteLoading: Bool = false
    private var currentCalculationTask: Task<Void, Never>?
    private let pathFinder: ECKCapitalJumpPathfinder = ECKCapitalJumpPathfinder()
    private var isInitialized: Bool = false
    
    public init(route: ECKCapitalJumpRoute? = nil) {
        let shipsArray = ECKSDEManager.shared.jumpCapableShips().map({ ship in
            return ECKJumpCapableShip(typeId: ship.typeId,
                                      name: ship.name,
                                      groupId: ship.groupId,
                                      groupName: ship.groupName,
                                      baseJumpRange: ship.baseJumpRange,
                                      fuelConsumption: ship.fuelConsumption)
        })
        
        var shipsGroupDict: [String: [ECKJumpCapableShip]] = [:]
        
        for ship in shipsArray {
            if shipsGroupDict[ship.groupName] == nil {
                shipsGroupDict[ship.groupName] = []
            }
            shipsGroupDict[ship.groupName]?.append(ship)
        }
        
        self.ships = shipsGroupDict.keys.sorted().map { key in
            return (groupName: key, ships: (shipsGroupDict[key] ?? []))
        }
        
        if let ship = route?.ship {
            selectedShip = ship
        } else {
            selectedShip = shipsArray.first
        }
        
        if let route = route {
            selectedDestinationSystems = route.destinationSystems
            selectedAvoidanceSystems = route.avoidanceSystems
            self.jdcSkillLevel = route.jdcSkillLevel
            self.jfcSkillLevel = route.jfcSkillLevel
            if let jfSkillLevel = route.jfSkillLevel {
                self.jumpFreighterSkillLevel = jfSkillLevel
            }
        }
        
        self.route = route
        isInitialized = true
    }
    
    nonisolated(nonsending) public func alternativeSystems(
        previousSystem: ECKSolarSystem,
        systemToReplace: ECKSolarSystem,
        nextSystem: ECKSolarSystem,
        jumpRange: Double
    ) async -> [ECKSolarSystem] {
        return await pathFinder.alternativeSystems(previousSystem: previousSystem,
                                                   systemToReplace: systemToReplace,
                                                   nextSystem: nextSystem,
                                                   jumpRange: jumpRange)
    }

    nonisolated(nonsending) public func systemsInRange(
        from originSystem: ECKSolarSystem,
        jumpRange: Double
    ) async -> [ECKSolarSystem] {
        let pathFinder = self.pathFinder

        return await withCheckedContinuation { continuation in
            DispatchQueue(label: "CapitalNavigationSystemRangeQueue", qos: .userInteractive).async {
                let jumpDistances = pathFinder.jumpDistances
                let systemSortComparator = KeyPathComparator(\ECKSolarSystem.solarSystemName)
                let systems = ECKCapitalJumpRangeSelector
                    .systemIdsInRange(from: originSystem.solarSystemId,
                                      jumpDistances: jumpDistances,
                                      jumpRange: jumpRange,
                                      excluding: [originSystem.solarSystemId])
                    .map({ ECKSolarSystem(solarSystemId: $0) })
                    .sorted(using: systemSortComparator)

                continuation.resume(returning: systems)
            }
        }
    }
    
    public func replaceRouteSystem(system: ECKCapitalJumpRoute.SystemEntry, with newSystem: ECKSolarSystem) {
        guard let route = route else {
            return
        }
        
        let newSystemEntries: [ECKCapitalJumpRoute.SystemEntry]? = route.route?.map({ entry in
            if entry.id == system.id {
                return .init(system: newSystem)
            } else {
                return entry
            }
        })
        
        let newRoute: ECKCapitalJumpRoute = .init(destinationSystems: route.destinationSystems,
                                                  avoidanceSystems: route.avoidanceSystems,
                                                  jdcSkillLevel: route.jdcSkillLevel,
                                                  jfcSkillLevel: route.jfcSkillLevel,
                                                  jfSkillLevel: route.jfSkillLevel,
                                                  ship: route.ship,
                                                  route: newSystemEntries)
        self.route = newRoute
    }
    
    private func reloadRoute() {
        guard isInitialized else {
            return
        }
        
        self.currentCalculationTask?.cancel()
        
        guard let jumpRange,
            let selectedShip else {
            self.route = nil
            self.isRouteLoading = false
            return
        }
        
        let jdcSkillLevel = self.jdcSkillLevel
        let jfcSkillLevel = self.jfcSkillLevel
        let jfSkillLevel = self.jumpFreighterSkillLevel
        
        self.currentCalculationTask = Task { @MainActor in
            let destinations = self.selectedDestinationSystems
            let systemsToAvoid = self.selectedAvoidanceSystems
            
            guard destinations.count >= 2 else {
                self.route = nil
                self.isRouteLoading = false
                return
            }
            
            self.isRouteLoading = true
            let calculatedRoute = await pathFinder.findPath(destinations: destinations.map({ $0.system }),
                                                            systemsToAvoid: systemsToAvoid.map({ $0.system }),
                                                            jumpRangeLY: jumpRange)
            
            let route = ECKCapitalJumpRoute(destinationSystems: selectedDestinationSystems,
                                            avoidanceSystems: selectedAvoidanceSystems,
                                            jdcSkillLevel: jdcSkillLevel,
                                            jfcSkillLevel: jfcSkillLevel,
                                            jfSkillLevel: selectedShip.isJumpFreighter ? jfSkillLevel : nil,
                                            ship: selectedShip,
                                            route: calculatedRoute)
            
            do {
                try Task.checkCancellation()
                self.route = route
            } catch {
                return
            }
            
            self.isRouteLoading = false
        }
    }
    
}
