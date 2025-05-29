//
//  ECKCharacterFitting+Calculate.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 26.05.25.
//

import Foundation

/// Reference: https://github.com/EVEShipFit/dogma-engine?tab=readme-ov-file#implementation

extension ECKCharacterFitting {
    
    internal func calculateAttributes(skills: ECKCharacterSkills) {
        pass1(skills: skills)
        pass2()
        pass3()
        pass4()
    }
    
}
