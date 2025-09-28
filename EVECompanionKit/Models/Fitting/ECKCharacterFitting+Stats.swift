//
//  ECKCharacterFitting+Stats.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

extension ECKCharacterFitting {
    
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
        }
    }
    
    // MARK: - Damage
    
    public struct DamageProfile {
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
    
    public enum ModuleSlotType: String {
        case rig
        case subsystem
        case high
        case mid
        case low
    }
    
}
