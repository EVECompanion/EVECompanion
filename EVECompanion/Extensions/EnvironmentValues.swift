//
//  EnvironmentValues.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.05.24.
//

import SwiftUI
import EVECompanionKit

private struct CharacterStorageKey: EnvironmentKey {
    static let defaultValue: ECKCharacterStorage = .init()
}

private struct SelectedCharacterKey: EnvironmentKey {
    static let defaultValue: CharacterSelection = .empty
}

extension EnvironmentValues {
    
    var characterStorage: ECKCharacterStorage {
      get { self[CharacterStorageKey.self] }
      set { self[CharacterStorageKey.self] = newValue }
    }
    
    var selectedCharacter: CharacterSelection {
        get { self[SelectedCharacterKey.self] }
        set { self[SelectedCharacterKey.self] = newValue }
    }
    
}
