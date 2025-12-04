//
//  SkillPlanView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import SwiftUI
import EVECompanionKit

struct SkillPlanView: View {
    
    @ObservedObject private var skillPlan: ECKSkillPlan
    private let manager: ECKSkillPlanManager
    @State private var showChangeNameAlert: Bool = false
    @State private var changeNameInput: String
    @State private var showEntrySelectionView: Bool = false
    
    init(skillPlan: ECKSkillPlan, manager: ECKSkillPlanManager) {
        self.skillPlan = skillPlan
        self.changeNameInput = skillPlan.name
        self.manager = manager
    }
    
    var body: some View {
        List {
            ForEach(skillPlan.entries) { entry in
                switch entry {
                case .remap(let remap):
                    SkillPlanRemapPointCell(remap: remap)
                case .skill(skill: let skill, level: let level):
                    SkillPlanSkillCell(skill: skill, skillLevel: level)
                        .contextMenu {
                            if level < 5 {
                                ForEach((level + 1)...5, id: \.self) { level in
                                    if skillPlan.contains(skillId: skill.id, level: level) == false {
                                        Button {
                                            skillPlan.addSkill(skill, level: level, manager: manager)
                                        } label: {
                                            Text("Train to \(level)")
                                        }
                                    }
                                }
                            }
                        }
                }
            }
            .onDelete { indexSet in
                skillPlan.remove(indexSet, manager: manager)
            }
        }
        .navigationTitle(skillPlan.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showChangeNameAlert = true
                } label: {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        skillPlan.addRemapPoint(manager: manager)
                    } label: {
                        HStack {
                            Image("Neocom/Augmentations")
                                .resizable()
                            Text("Add Remap Point")
                        }
                    }
                    
                    Button {
                        showEntrySelectionView = true
                    } label: {
                        HStack {
                            Image("Neocom/Skills")
                                .resizable()
                            Text("Add Skill")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Change name", isPresented: $showChangeNameAlert) {
            TextField("Skill Plan Name", text: $changeNameInput)
            Button {
                skillPlan.setName(changeNameInput, manager: manager)
            } label: {
                Text("Ok")
            }
            
            Button(role: .cancel) {
                changeNameInput = skillPlan.name
            } label: {
                Text("Cancel")
            }
        }
        .sheet(isPresented: $showEntrySelectionView) {
            SkillPlanSelectionView { item in
                skillPlan.addItem(item,
                                  manager: manager)
            }
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .skillPlanDetail(.dummy, .init(character: .dummy, isPreview: true)))
}
