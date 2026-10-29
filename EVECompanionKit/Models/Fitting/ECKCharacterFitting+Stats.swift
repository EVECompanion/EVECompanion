//
//  ECKCharacterFitting+Stats.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

private struct CapacitorDrain {
    let cycleMilliseconds: Float
    let activationCost: Float
    let quantity: Int

    var usePerSecond: Float {
        activationCost * Float(quantity) * 1_000 / cycleMilliseconds
    }
}

extension ECKCharacterFitting {

    // MARK: - Capacitor

    public struct CapacitorStability {
        public let isStable: Bool
        public let timeToEmpty: TimeInterval?

        public init(isStable: Bool, timeToEmpty: TimeInterval?) {
            self.isStable = isStable
            self.timeToEmpty = timeToEmpty
        }
    }

    public var capacitorStability: CapacitorStability? {
        guard let capacity = ship.attributes[Self.attributeCapacitorCapacityId].map({ $0.value ?? $0.baseValue }),
              let rechargeMilliseconds = ship.attributes[Self.attributeCapacitorRechargeTimeId].map({ $0.value ?? $0.baseValue }),
              capacity > 0,
              rechargeMilliseconds > 0 else {
            return nil
        }

        let drains = items.compactMap { item -> CapacitorDrain? in
            guard item.state.rawValue >= ECKDogmaEffect.Category.active.rawValue,
                  let activationCost = item.attributes[Self.attributeCapacitorUseId].map({ $0.value ?? $0.baseValue }) else {
                return nil
            }

            let cycleMilliseconds = [Self.attributeRoFId,
                                     Self.attributeActivationTimeId,
                                     Self.attributeActivationTimeHighIsGoodId]
                .compactMap { item.attributes[$0].map({ $0.value ?? $0.baseValue }) }
                .max() ?? 0
            guard cycleMilliseconds > 0, activationCost > 0 else {
                return nil
            }
            return .init(cycleMilliseconds: cycleMilliseconds,
                         activationCost: activationCost,
                         quantity: max(item.quantity, 1))
        }

        let capacitorUsePerSecond = drains.reduce(Float.zero) { $0 + $1.usePerSecond }
        let rechargeTime = rechargeMilliseconds / 1_000
        let peakRecharge = capacity * 2.5 / rechargeTime
        guard capacitorUsePerSecond > peakRecharge else {
            return .init(isStable: true, timeToEmpty: nil)
        }

        var remainingCapacitor = capacity
        var elapsed: Float = 0
        var nextActivations = Array(repeating: Float.zero, count: drains.count)
        var activationCount = 0
        while remainingCapacitor > 0 {
            guard let nextActivation = nextActivations.min() else {
                break
            }
            let elapsedSinceLastActivation = nextActivation - elapsed
            if elapsedSinceLastActivation > 0 {
                let chargeFraction = max(remainingCapacitor / capacity, 0)
                let rechargeFactor = exp(-5 * elapsedSinceLastActivation / rechargeTime)
                remainingCapacitor = capacity * pow(1 + (sqrt(chargeFraction) - 1) * rechargeFactor, 2)
                elapsed = nextActivation
            }

            var activationCost: Float = 0
            for index in drains.indices where nextActivations[index] == nextActivation {
                activationCost += drains[index].activationCost * Float(drains[index].quantity)
                nextActivations[index] += drains[index].cycleMilliseconds / 1_000
            }
            remainingCapacitor -= activationCost
            activationCount += 1

            if activationCount >= 100_000 {
                return .init(isStable: false,
                             timeToEmpty: TimeInterval(elapsed + Self.estimatedDepletionTime(capacitor: max(remainingCapacitor, 0),
                                                                                             capacity: capacity,
                                                                                             rechargeTime: rechargeTime,
                                                                                             capacitorUsePerSecond: capacitorUsePerSecond)))
            }
        }
        return .init(isStable: false, timeToEmpty: TimeInterval(elapsed))
    }

    private static func estimatedDepletionTime(capacitor: Float,
                                               capacity: Float,
                                               rechargeTime: Float,
                                               capacitorUsePerSecond: Float) -> Float {
        var remainingCapacitor = capacitor
        var elapsed: Float = 0
        let step: Float = 1
        while remainingCapacitor > 0 {
            let fraction = remainingCapacitor / capacity
            let recharge = capacity * 10 / rechargeTime * (sqrt(fraction) - fraction)
            remainingCapacitor = max(0, remainingCapacitor - (capacitorUsePerSecond - recharge) * step)
            elapsed += step
        }
        return elapsed
    }

    static let attributeCapacitorUseId = 6
    static let attributeCapacitorRechargeTimeId = 55
    
    // MARK: - Resistances
    
    public struct Resistances {
        public let structure: ResistanceStats
        public let armor: ResistanceStats
        public let shield: ResistanceStats
        
        public init(structure: ResistanceStats, armor: ResistanceStats, shield: ResistanceStats) {
            self.structure = structure
            self.armor = armor
            self.shield = shield
        }
    }
    
    public struct ResistanceStats {
        public let ehp: Float
        public let hp: Float
        public let em: Float
        public let explosive: Float
        public let kinetic: Float
        public let thermal: Float
        
        public init(hp: Float, em: Float, explosive: Float, kinetic: Float, thermal: Float) {
            self.hp = hp
            self.em = em
            self.explosive = explosive
            self.kinetic = kinetic
            self.thermal = thermal
            let averageResist = (em + explosive + kinetic + thermal) / 4.0
            self.ehp = hp / averageResist
        }
    }
    
    // MARK: - Damage
    
    public struct DamageProfile: Sendable {
        public let em: Float
        public let explosive: Float
        public let kinetic: Float
        public let thermal: Float
        
        public let emDPS: Float
        public let explosiveDPS: Float
        public let kineticDPS: Float
        public let thermalDPS: Float
        
        public let volleyDamage: Float
        public let dpsWithReload: Float
        public let dpsWithoutReload: Float
        
        static let zero: DamageProfile = .init(em: 0,
                                               explosive: 0,
                                               kinetic: 0,
                                               thermal: 0,
                                               emDPS: 0,
                                               explosiveDPS: 0,
                                               kineticDPS: 0,
                                               thermalDPS: 0,
                                               volleyDamage: 0,
                                               dpsWithReload: 0,
                                               dpsWithoutReload: 0)
        public static let dummy: DamageProfile = .init(em: 25,
                                                       explosive: 50,
                                                       kinetic: 75,
                                                       thermal: 100,
                                                       emDPS: 25,
                                                       explosiveDPS: 50,
                                                       kineticDPS: 75,
                                                       thermalDPS: 100,
                                                       volleyDamage: 250,
                                                       dpsWithReload: 100,
                                                       dpsWithoutReload: 120)
        
        init(em: Float,
             explosive: Float,
             kinetic: Float,
             thermal: Float,
             emDPS: Float,
             explosiveDPS: Float,
             kineticDPS: Float,
             thermalDPS: Float,
             volleyDamage: Float,
             dpsWithReload: Float,
             dpsWithoutReload: Float) {
            self.em = em
            self.explosive = explosive
            self.kinetic = kinetic
            self.thermal = thermal
            self.emDPS = emDPS
            self.explosiveDPS = explosiveDPS
            self.kineticDPS = kineticDPS
            self.thermalDPS = thermalDPS
            self.volleyDamage = volleyDamage
            self.dpsWithReload = dpsWithReload
            self.dpsWithoutReload = dpsWithoutReload
        }
        
        public var containsDamage: Bool {
            return em > 0 || explosive > 0 || kinetic > 0 || thermal > 0
        }
        
        static func + (lhs: DamageProfile, rhs: DamageProfile) -> DamageProfile {
            return .init(em: lhs.em + rhs.em,
                         explosive: lhs.explosive + rhs.explosive,
                         kinetic: lhs.kinetic + rhs.kinetic,
                         thermal: lhs.thermal + rhs.thermal,
                         emDPS: lhs.emDPS + rhs.emDPS,
                         explosiveDPS: lhs.explosiveDPS + rhs.explosiveDPS,
                         kineticDPS: lhs.kineticDPS + rhs.kineticDPS,
                         thermalDPS: lhs.thermalDPS + rhs.thermalDPS,
                         volleyDamage: lhs.volleyDamage + rhs.volleyDamage,
                         dpsWithReload: lhs.dpsWithReload + rhs.dpsWithReload,
                         dpsWithoutReload: lhs.dpsWithoutReload + rhs.dpsWithoutReload)
        }
        
    }
    
    // MARK: - Slot Type
    
    public enum ModuleSlotType: String, Sendable {
        case rig
        case subsystem
        case high
        case mid
        case low
        
        var name: String {
            switch self {
            case .rig:
                return "rig slot"
            case .subsystem:
                return "subsystem slot"
            case .high:
                return "high slot"
            case .mid:
                return "mid slot"
            case .low:
                return "low slot"
            }
        }
    }

    // MARK: - Fighter Types
    
    public enum FighterType: String, CaseIterable, Identifiable, Sendable {
        case light
        case support
        case heavy

        public var id: String {
            return rawValue
        }

        public var title: String {
            switch self {
            case .light:
                return "Light"
            case .support:
                return "Support"
            case .heavy:
                return "Heavy"
            }
        }

        public var pluralTitle: String {
            return "\(title) Fighters"
        }

        public var carrierGroupId: Int {
            switch self {
            case .light:
                return 1652
            case .support:
                return 1537
            case .heavy:
                return 1653
            }
        }
    }
    
}
