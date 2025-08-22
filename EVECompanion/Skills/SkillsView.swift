//
//  SkillsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit

struct SkillsView: View {
    
    @ObservedObject var character: ECKCharacter
    @State var searchString: String = ""
    
    var skills: [String: [ECKCharacterSkillLevel]] {
        var skills: [String: [ECKCharacterSkillLevel]] = [:]
        
        character.skills?.skillLevels.forEach({ skillLevel in
            if searchString.isEmpty == false && skillLevel.skill.name.lowercased().contains(searchString.lowercased()) == false {
                return
            }
            
            let category = skillLevel.skill.category
            if skills[category] != nil {
                skills[category]?.append(skillLevel)
            } else {
                skills[category] = [skillLevel]
            }
        })
        
        skills.keys.forEach { key in
            skills[key] = (skills[key] ?? []).sorted { lhsSkill, rhsSkill in
                return lhsSkill.skill.name < rhsSkill.skill.name
            }
        }
        
        return skills
    }
    
    var body: some View {
        List {
            ForEach(skills.keys.sorted(), id: \.self) { category in
                Section(category) {
                    ForEach(skills[category] ?? []) { skillLevel in
                        NavigationLink(value: AppScreen.itemByTypeId(skillLevel.skill.skillId)) {
                            SkillCell(level: skillLevel)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchString)
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
