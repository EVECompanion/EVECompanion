//
//  ECKCharacterFitting+Calculate+Pass2.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation

extension ECKCharacterFitting {
    
    internal func pass2() {
        
    }
    
}

struct ECKPass2Effect {
    
}

private extension ECKItem {
    
    func collectEffects(into effects: inout [ECKPass2Effect]) {
        let effects = ECKSDEManager.shared.getEffects(for: typeId)
        
        for effect in effects {
            
        }
    }
    
}
