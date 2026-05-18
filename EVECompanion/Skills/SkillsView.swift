//
//  SkillsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit
import Combine

@MainActor
private final class SkillsViewModel: ObservableObject {
    
    struct SkillEntry: Identifiable {
        let skill: ECKCharacterSkill
        let trainedLevel: Int?
        
        var id: Int {
            skill.skillId
        }
    }
    
    struct SkillSection: Identifiable {
        let category: String
        let skills: [SkillEntry]
        
        var id: String {
            category
        }
    }
    
    @Published var searchString: String = ""
    
    private var allSkills: [ECKCharacterSkill] = []
    
    func loadSkillsIfNeeded() {
        guard allSkills.isEmpty else {
            return
        }
        
        allSkills = ECKSDEManager.shared.allSkills()
    }
    
    func sections(characterSkills: ECKCharacterSkills?) -> [SkillSection] {
        let groupedSkills = Dictionary(grouping: filteredSkills) { skill in
            skill.category
        }
        
        return groupedSkills.keys.sorted().map { category in
            let entries = (groupedSkills[category] ?? []).map { skill in
                SkillEntry(skill: skill,
                           trainedLevel: characterSkills?.skillLevel(typeId: skill.skillId)?.trainedSkillLevel)
            }
            .sorted { lhsSkill, rhsSkill in
                lhsSkill.skill.name < rhsSkill.skill.name
            }
            
            return SkillSection(category: category,
                                skills: entries)
        }
    }
    
    private var filteredSkills: [ECKCharacterSkill] {
        guard searchString.isEmpty == false else {
            return allSkills
        }
        
        let normalizedSearchString = searchString.lowercased()
        return allSkills.filter { skill in
            skill.name.lowercased().contains(normalizedSearchString)
        }
    }
    
}

struct SkillsView: View {
    
    @ObservedObject var character: ECKCharacter
    @StateObject private var viewModel = SkillsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.sections(characterSkills: character.skills)) { section in
                Section(section.category) {
                    ForEach(section.skills) { skill in
                        NavigationLink(value: AppScreen.itemByTypeId(skill.skill.skillId)) {
                            SkillCell(skill: skill.skill,
                                      trainedLevel: skill.trainedLevel)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchString)
        .task {
            viewModel.loadSkillsIfNeeded()
        }
        .refreshable {
            await character.reloadSkills()
        }
        .navigationTitle("Skills")
    }
}

#Preview {
    NavigationStack {
        SkillsView(character: .dummy)
    }
}
