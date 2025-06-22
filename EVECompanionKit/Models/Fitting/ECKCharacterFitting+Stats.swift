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
    
}
