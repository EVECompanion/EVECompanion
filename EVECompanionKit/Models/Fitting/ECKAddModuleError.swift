//
//  ECKAddModuleError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 27.09.25.
//

import Foundation

public enum ECKAddModuleError: Error, Identifiable {
    
    case generic
    case moduleNotFittable(ECKItem)
    case moduleMaxCountReached(group: String, maxCount: Int)
    case notEnoughLauncherHardpoints
    case notEnoughTurretHardpoints
    case noFreeSlot(ECKItem, ECKCharacterFitting.ModuleSlotType)
    case subsystemIncompatible(ECKItem)
    case subsystemSlotAlreadyOccupied(ECKItem, fittedSubsystem: ECKItem)
    
    public var id: String {
        switch self {
        case .generic:
            return "generic"
        case .moduleNotFittable(let item):
            return "moduleNotFittable-\(item.id)"
        case .noFreeSlot(let item, let moduleSlotType):
            return "noFreeSlot-\(item.id)-\(moduleSlotType.rawValue)"
        case .moduleMaxCountReached(group: let group, maxCount: let maxCount):
            return "moduleMaxCountReached-\(group)-\(maxCount)"
        case .notEnoughLauncherHardpoints:
            return "notEnoughLauncherHardpoints"
        case .notEnoughTurretHardpoints:
            return "notEnoughTurretHardpoints"
        case .subsystemIncompatible(let item):
            return "subsystemIncompatible-\(item.id)"
        case .subsystemSlotAlreadyOccupied(let item, fittedSubsystem: let fittedSubsystem):
            return "subsystemSlotAlreadyOccupied-\(item.id)-\(fittedSubsystem.id)"
        }
    }
    
    public var text: String {
        switch self {
        case .generic:
            return "An unknown error occurred."
        case .moduleNotFittable(let item):
            return "The module \(item.name) is not compatible with your ship."
        case .noFreeSlot(let item, let slotType):
            return "There is no free \(slotType.name) in your ship for the module \(item.name)."
        case .moduleMaxCountReached(group: let group, maxCount: let maxCount):
            return "You can only fit \(maxCount) \(maxCount > 1 ? "modules" : "module") of the item group \(group)."
        case .notEnoughLauncherHardpoints:
            return "You don't have enough free launcher hardpoints for the added modules."
        case .notEnoughTurretHardpoints:
            return "You don't have enough free turret hardpoints for the added modules."
        case .subsystemIncompatible(let item):
            return "The subsystem \(item.name) is incompatible with this ship."
        case .subsystemSlotAlreadyOccupied(let item, fittedSubsystem: let fittedSubsystem):
            return "The subsystem \(item.name) cannot be fitted as it uses the same slot as \(fittedSubsystem.name)."
        }
    }
    
}
