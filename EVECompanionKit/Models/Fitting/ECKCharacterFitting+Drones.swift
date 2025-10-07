//
//  ECKCharacterFitting+Drones.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.10.25.
//

import Foundation

extension ECKCharacterFitting {
    
    public func addDrone(newDrone: ECKItem, manager: ECKFittingManager) {
        let item = ECKCharacterFittingItem(flag: .DroneBay, quantity: 5, item: newDrone)
        drones.append(item)
        calculateAttributes(skills: nil)
        manager.saveFitting(self)
    }
    
}
