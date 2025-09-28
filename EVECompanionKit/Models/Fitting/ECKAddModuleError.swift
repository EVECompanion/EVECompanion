//
//  ECKAddModuleError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 27.09.25.
//

import Foundation

public enum ECKAddModuleError: Error {
    
    case generic
    case moduleNotFittable(ECKItem)
    case noFreeSlot(ECKItem, ECKCharacterFitting.ModuleSlotType)
    
}
