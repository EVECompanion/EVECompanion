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
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }
    
    public func removeDrone(_ drone: ECKCharacterFittingItem, manager: ECKFittingManager) {
        self.drones = self.drones.filter({ $0.id != drone.id })
        objectWillChange.send()
        manager.saveFitting(self)
    }
    
}
