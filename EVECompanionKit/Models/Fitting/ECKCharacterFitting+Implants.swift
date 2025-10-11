//
//  ECKCharacterFitting+Implants.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.10.25.
//

import Foundation

extension ECKCharacterFitting {
    
    public func addImplant(newImplant: ECKItem,
                           implantToReplace: ECKCharacterFittingItem?,
                           manager: ECKFittingManager) {
        let item = ECKCharacterFittingItem(flag: .Implant, quantity: 1, item: newImplant)
        
        if let implantToReplace {
            self.implants = self.implants.filter({ $0.id != implantToReplace.id })
        }
        
        self.implants.append(item)
        
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }
    
    public func removeImplant(_ implant: ECKCharacterFittingItem, manager: ECKFittingManager) {
        self.implants = self.implants.filter({ $0.id != implant.id })
        Task {
            await calculateAttributes(skills: nil)
        }
        manager.saveFitting(self)
    }
    
}
