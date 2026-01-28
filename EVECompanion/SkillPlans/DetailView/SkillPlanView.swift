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
                        .deleteDisabled(true)
                case .skill(let skillEntry):
                    SkillPlanSkillCell(entry: skillEntry)
                        .contextMenu {
                            if skillEntry.level < 5 {
                                ForEach((skillEntry.level + 1)...5, id: \.self) { level in
                                    if skillPlan.contains(skillId: skillEntry.skill.id, level: level) == false {
                                        Button {
                                            skillPlan.addSkill(skillEntry.skill, level: level, manager: manager)
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
            .onMove { fromOffsets, toOffset in
                skillPlan.move(fromOffsets: fromOffsets, toOffset: toOffset, manager: manager)
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
        .onAppear {
            skillPlan.recalculateRemapPoints()
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .skillPlanDetail(.dummy, .init(character: .dummy, isPreview: true)))
}
