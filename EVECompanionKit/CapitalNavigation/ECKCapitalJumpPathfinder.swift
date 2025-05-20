//
//  ECKCapitalJumpPathfinder.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.08.24.
//

import Foundation
import SwiftPriorityQueue
import simd

public actor ECKCapitalJumpPathfinder {
    
    private static let dispatchQueueLabel: String = "CapitalJumpPathFinderQueue"
    
    lazy var jumpDistances: [Int: [Int: Double]] = {
        let allLSDistances = ECKSDEManager.shared.capitalLSJumpDistances()
        let allHSDistances = ECKSDEManager.shared.capitalHSToLSJumpDistances()
        
        var distances: [Int: [Int: Double]] = [:]
        
        for distanceValue in allLSDistances {
            if distances[distanceValue.systemAId] == nil {
                distances[distanceValue.systemAId] = [:]
            }
            
            distances[distanceValue.systemAId]?[distanceValue.systemBId] = distanceValue.distance
            
            if distances[distanceValue.systemBId] == nil {
                distances[distanceValue.systemBId] = [:]
            }
            
            distances[distanceValue.systemBId]?[distanceValue.systemAId] = distanceValue.distance
        }
        
        for distanceValue in allHSDistances {
            if distances[distanceValue.systemAId] == nil {
                distances[distanceValue.systemAId] = [:]
            }
            
            distances[distanceValue.systemAId]?[distanceValue.systemBId] = distanceValue.distance
        }
        
        return distances
    }()
    
    private class JumpPathNode: Comparable {
        
        static let ccpLY: Double = 9460000000000000
        static let extraJumpFactor: Double = 10
        
        let systemId: Int
        let startSystem: ECKSolarSystem
        let destinationSystem: ECKSolarSystem
        let totalDistanceStartToDestination: Float
        let totalDistanceToThisNode: Float
        let totalJumpsToThisNode: Int
        
        var previousNode: JumpPathNode?
        var distanceToPreviousNode: Double?
        
        init(systemId: Int,
             startSystem: ECKSolarSystem,
             destinationSystem: ECKSolarSystem,
             totalDistanceStartToDestination: Float,
             totalDistanceToThisNode: Float,
             totalJumpsToThisNode: Int,
             previousNode: JumpPathNode? = nil,
             distanceToPreviousNode: Double? = nil) {
            self.systemId = systemId
            self.startSystem = startSystem
            self.destinationSystem = destinationSystem
            self.totalDistanceStartToDestination = totalDistanceStartToDestination
            self.totalDistanceToThisNode = totalDistanceToThisNode
            self.totalJumpsToThisNode = totalJumpsToThisNode
            self.previousNode = previousNode
            self.distanceToPreviousNode = distanceToPreviousNode
        }
        
        lazy var gValue: Double = {
            var value: Double = 0
            
            value += Double(totalJumpsToThisNode) * Self.extraJumpFactor
            value += Double(totalDistanceToThisNode)
            
            return value
        }()
        
        var hValue: Float {
            return Float(totalJumpsToThisNode)
        }
        
        var fValue: Double {
            return gValue + Double(hValue)
        }
        
        static func < (lhs: ECKCapitalJumpPathfinder.JumpPathNode, rhs: ECKCapitalJumpPathfinder.JumpPathNode) -> Bool {
            return lhs.fValue < rhs.fValue
        }
        
        static func == (lhs: ECKCapitalJumpPathfinder.JumpPathNode, rhs: ECKCapitalJumpPathfinder.JumpPathNode) -> Bool {
            return lhs.gValue == rhs.gValue && lhs.systemId == rhs.systemId
        }
        
    }
    
    public init() {
        
    }
    
    @MainActor
    public func findPath(destinations: [ECKSolarSystem], systemsToAvoid: [ECKSolarSystem], jumpRangeLY: Double) async -> [ECKSolarSystem]? {
        guard destinations.count >= 2 else {
            return []
        }
        
        return try? await withCheckedThrowingContinuation { continuation in
            DispatchQueue(label: Self.dispatchQueueLabel, qos: .userInteractive).async {
                let paths = zip(destinations.dropLast(), destinations.dropFirst())
                
                var jumpPath: [ECKSolarSystem] = []
                for path in paths.enumerated() {
                    guard var jumps = Self.aStar(jumpDistances: self.jumpDistances,
                                                 startSystem: path.element.0,
                                                 destinationSystem: path.element.1,
                                                 systemsToAvoid: Set(systemsToAvoid.map({ $0.solarSystemId })),
                                                 jumpRangeLY: jumpRangeLY) else {
                        continuation.resume(throwing: ECKCapitalJumpPathFinderError.routingError)
                        return
                    }
                    
                    if path.offset > 0 {
                        jumps = Array(jumps.dropFirst())
                    }
                    
                    jumpPath.append(contentsOf: jumps)
                }
                
                continuation.resume(returning: jumpPath)
            }
        }
    }
    
    private static func aStar(jumpDistances: [Int: [Int: Double]],
                              startSystem: ECKSolarSystem,
                              destinationSystem: ECKSolarSystem,
                              systemsToAvoid: Set<Int>,
                              jumpRangeLY: Double) -> [ECKSolarSystem]? {
        let startTime = DispatchTime.now()
        
        let totalDistanceStartToDestination = simd_distance(startSystem.position, destinationSystem.position)
        let startNode = JumpPathNode(systemId: startSystem.solarSystemId,
                                     startSystem: startSystem,
                                     destinationSystem: destinationSystem,
                                     totalDistanceStartToDestination: totalDistanceStartToDestination,
                                     totalDistanceToThisNode: 0,
                                     totalJumpsToThisNode: 0)
        var openList: PriorityQueue<JumpPathNode> = .init(ascending: true, startingValues: [startNode])
        
        // Here, we just store the system IDs that we already visited.
        var closedList: Set<Int> = .init()
        var storedNodes: [Int: JumpPathNode] = [:]
        
        storedNodes[startNode.systemId] = startNode
        
        while openList.isEmpty == false {
            guard let currentNode = openList.pop() else {
                logger.error("No Min value found.")
                // ERROR STATE, NO PATH FOUND
                return []
            }
            
            // Ensure that the node is not visited again
            closedList.insert(currentNode.systemId)
            
            let systemsToEvaluate = (jumpDistances[currentNode.systemId] ?? [:]).filter { entry in
                return systemsToAvoid.contains(entry.key) == false
            }
            
            let nodesToEvaluate: [JumpPathNode] = systemsToEvaluate.compactMap { system -> JumpPathNode? in
                guard system.value <= jumpRangeLY else {
                    return nil
                }
                
                return JumpPathNode(systemId: system.key,
                                    startSystem: startSystem,
                                    destinationSystem: destinationSystem,
                                    totalDistanceStartToDestination: totalDistanceStartToDestination,
                                    totalDistanceToThisNode: currentNode.totalDistanceToThisNode + Float(system.value),
                                    totalJumpsToThisNode: currentNode.totalJumpsToThisNode + 1,
                                    previousNode: currentNode,
                                    distanceToPreviousNode: system.value)
            }
            
            for node in nodesToEvaluate {
                if node.systemId == destinationSystem.solarSystemId {
                    // Path found, reconstruct it
                    return reconstructPath(lastNode: node, startTime: startTime)
                } else {
                    guard closedList.contains(node.systemId) == false else {
                        continue
                    }
                    
                    let storedNode = storedNodes[node.systemId]
                    
                    if let storedNode {
                        if storedNode.gValue <= node.gValue {
                            continue
                        } else {
                            openList.remove(storedNode)
                        }
                    }
                    
                    openList.push(node)
                    storedNodes[node.systemId] = node
                }
            }
        }
        
        // ERROR STATE, NO PATH FOUND
        return nil
    }
    
    private static func reconstructPath(lastNode: JumpPathNode, startTime: DispatchTime) -> [ECKSolarSystem]? {
        var path: [Int] = [lastNode.systemId]
        var currentNode = lastNode
        
        while let previousNode = currentNode.previousNode {
            currentNode = previousNode
            path.insert(previousNode.systemId, at: 0)
        }
        
        let endTime = DispatchTime.now()
        
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        let systemPath = path.map({ ECKSolarSystem(solarSystemId: $0) })
        print("Calculation took \(timeInterval) seconds")
        print("Numer of Jumps: \(systemPath.count - 1)")
        print("Path: \(systemPath.map({ $0.solarSystemName }).joined(separator: ":"))")
        print("Total Distance: \(lastNode.totalDistanceToThisNode)")
        
        return systemPath
    }
    
    @MainActor
    internal func alternativeSystems(previousSystem: ECKSolarSystem,
                                     systemToReplace: ECKSolarSystem,
                                     nextSystem: ECKSolarSystem,
                                     jumpRange: Double) async -> [ECKSolarSystem] {
        return await withCheckedContinuation { continuation in
            DispatchQueue(label: Self.dispatchQueueLabel, qos: .userInteractive).async {
                // First, get all possible connections from previousSystem
                var candidates = self.jumpDistances[previousSystem.solarSystemId] ?? [:]
                
                // Now filter out all candidates which are not in jump range
                candidates = candidates.filter { element in
                    return element.value <= jumpRange
                }
                
                // Lastly, filter out all candidates which are not in jump range to the previous system
                candidates = candidates.filter { element in
                    let candidateSystemId = element.key
                    
                    // Get Jump range from the candidate to the next system
                    guard let distanceToNext = self.jumpDistances[candidateSystemId]?[nextSystem.solarSystemId] else {
                        return false
                    }
                    
                    guard element.key != systemToReplace.solarSystemId else {
                        return false
                    }
                    
                    return distanceToNext <= jumpRange
                }
                
                let systemSortComparator = KeyPathComparator(\ECKSolarSystem.solarSystemName)
                let systems = Array(candidates.keys).map({ ECKSolarSystem(solarSystemId: $0) }).sorted(using: systemSortComparator)
                continuation.resume(returning: systems)
            }
        }
    }
    
}
