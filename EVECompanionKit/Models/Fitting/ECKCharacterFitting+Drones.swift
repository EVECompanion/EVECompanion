//
//  ECKCharacterFitting+Drones.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.10.25.
//

import Foundation
import Combine

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

    public func replaceDrone(_ drone: ECKCharacterFittingItem, with newDrone: ECKItem, manager: ECKFittingManager) {
        let replacement = ECKCharacterFittingItem(flag: drone.flag,
                                                  quantity: drone.quantity,
                                                  item: newDrone)
        replacement.state = drone.state
        drones = drones.map { $0.id == drone.id ? replacement : $0 }
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }
    
    public func addFighter(newFighter: ECKItem, manager: ECKFittingManager) {
        guard let fighterType = newFighter.fighterType,
              canAddFighter(ofType: fighterType) else {
            return
        }

        let item = ECKCharacterFittingItem(flag: .init(rawValue: "FighterTube\(fighters.count)")!,
                                           quantity: 1,
                                           item: newFighter)
        fighters.append(item)
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }

    public func replaceFighter(_ fighter: ECKCharacterFittingItem, with newFighter: ECKItem, manager: ECKFittingManager) {
        guard let fighterType = newFighter.fighterType,
              canAddFighter(ofType: fighterType) || fighter.item.fighterType == fighterType else {
            return
        }

        let replacement = ECKCharacterFittingItem(flag: fighter.flag,
                                                  quantity: fighter.quantity,
                                                  item: newFighter)
        replacement.state = fighter.state
        fighters = fighters.map { $0.id == fighter.id ? replacement : $0 }
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }

    public func removeFighter(_ fighter: ECKCharacterFittingItem, manager: ECKFittingManager) {
        fighters = fighters.filter({ $0.id != fighter.id })
        fixModuleFlags()
        objectWillChange.send()
        manager.saveFitting(self)
    }
    
}
