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
    @Environment(\.serviceManager) private var serviceManager
    @EnvironmentObject private var coordinator: Coordinator
    
    @State private var didReadEnvCharacter: Bool = false
        
    var untrainedSkillsOfSelectedCharacter: [ECKItem.SkillRequirement] {
        guard let skills = selectedCharacter.character?.skills else {
            return []
        }
        
        return (item.skillRequirements ?? []).filter({
            skills.isTrained(skillId: $0.skill.id, level: $0.requiredLevel) == false
        })
    }
    
    var skillPlansOfSelectedCharacter: [ECKSkillPlan] {
        guard let selectedCharacter = selectedCharacter.character else {
            return []
        }
        
        return serviceManager.skillPlanManager(character: selectedCharacter).skillPlans
    }
    
    var skillPlanManagerOfSelectedCharacter: ECKSkillPlanManager? {
        guard let selectedCharacter = selectedCharacter.character else {
            return nil
        }
        
        return serviceManager.skillPlanManager(character: selectedCharacter)
    }
    
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
        } footer: {
            if untrainedSkillsOfSelectedCharacter.isEmpty == false {
                Menu {
                    if skillPlansOfSelectedCharacter.isEmpty == false {
                        Section("Add to existing Skill Plan") {
                            ForEach(skillPlansOfSelectedCharacter) { skillPlan in
                                Button {
                                    guard let skillPlanManager = skillPlanManagerOfSelectedCharacter else {
                                        return
                                    }
                                    
                                    skillPlan.addItem(item, manager: skillPlanManager)
                                    coordinator.push(screen: .skillPlanDetail(skillPlan, skillPlanManager))
                                } label: {
                                    Text(skillPlan.name)
                                }
                            }
                        }
                    }
                    
                    Section("Add to new Skill Plan") {
                        Button {
                            guard let skillPlanManager = skillPlanManagerOfSelectedCharacter else {
                                return
                            }
                            
                            let newPlan = skillPlanManager.createSkillPlan()
                            newPlan.addItem(item, manager: skillPlanManager)
                            coordinator.push(screen: .skillPlanDetail(newPlan, skillPlanManager))
                        } label: {
                            Text("Create new Skill Plan")
                        }
                    }
                } label: {
                    Text("Add to Skill Plan")
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
            .environment(\.selectedCharacter, CharacterSelection.character(.dummy))
    }
}
