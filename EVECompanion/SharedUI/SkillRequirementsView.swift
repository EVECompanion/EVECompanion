//
//  SkillRequirementsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 17.04.25.
//

import SwiftUI
import EVECompanionKit

struct SkillRequirementsView: View {
    
    private let item: ECKItem
    @State private var selectedCharacter: CharacterSelection = .empty
    @Environment(\.selectedCharacter) var envCharacter
    @Environment(\.characterStorage) var characterStorage
    
    @State private var didReadEnvCharacter: Bool = false
    
    init(item: ECKItem) {
        self.item = item
    }
    
    var body: some View {
        Section {
            OutlineGroup(item.skillRequirements ?? [], children: \.skill.skillRequirements) { requirement in
                HStack {
                    if case let CharacterSelection.character(character) = selectedCharacter,
                       let skills = character.skills {
                        if skills.isTrained(skillId: requirement.skill.id, level: requirement.requiredLevel) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Text(requirement.skill.name + " " + ECFormatters.skillLevel(level: requirement.requiredLevel))
                }
                .animation(.spring, value: selectedCharacter)
            }
        } header: {
            HStack {
                Text("Required Skills")
                
                Spacer()
                
                Menu {
                    ForEach(characterStorage.characters) { character in
                        Button {
                            self.selectedCharacter = .character(character)
                        } label: {
                            Text(character.name)
                        }
                    }
                } label: {
                    HStack {
                        switch selectedCharacter {
                        case .empty:
                            Text("Pick a Character")
                        case .character(let character):
                            Text(character.name)
                        }
                        
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
            }
        }
        .onAppear {
            guard didReadEnvCharacter == false else {
                return
            }
            
            didReadEnvCharacter = true
            self.selectedCharacter = envCharacter
        }
    }
    
}

#Preview {
    List {
        SkillRequirementsView(item: .init(typeId: 11567))
    }
}
