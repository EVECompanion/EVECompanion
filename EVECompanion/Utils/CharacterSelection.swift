//
//  CharacterSelection.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 17.04.25.
//

import Foundation
import EVECompanionKit

enum CharacterSelection: Hashable {
    case empty
    case character(ECKCharacter)
    
    var character: ECKCharacter? {
        switch self {
        case .character(let character):
            return character
        case .empty:
            return nil
        }
    }
}
