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
    case noFreeSlot(ECKItem, ECKCharacterFitting.ModuleSlotType)
    
    public var id: String {
        switch self {
        case .generic:
            return "generic"
        case .moduleNotFittable(let item):
            return "moduleNotFittable-\(item.id)"
        case .noFreeSlot(let item, let moduleSlotType):
            return "noFreeSlot-\(item.id)-\(moduleSlotType.rawValue)"
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
        }
    }
    
}
