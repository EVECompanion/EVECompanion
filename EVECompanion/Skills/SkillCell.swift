//
//  SkillCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit

struct SkillCell: View {
    
    let skill: ECKCharacterSkill
    let trainedLevel: Int?
    
    var body: some View {
        HStack {
            Text(titleText)
                .foregroundStyle(trainedLevel == nil ? .secondary : .primary)
            
            Spacer()
            
            HStack {
                if let trainedLevel {
                    HStack(spacing: 5) {
                        ForEach(1...5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(index <= trainedLevel ? Color.blue : Color.clear)
                        }
                    }
                } else {
                    Text("Not injected")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        }
    }
    
    private var titleText: String {
        if let trainedLevel {
            return "\(skill.name) \(ECFormatters.skillLevel(level: trainedLevel))"
        } else {
            return skill.name
        }
    }
}

#Preview {
    List {
        Section("Spaceship Command") {
            SkillCell(skill: ECKCharacterSkill.dummy1,
                      trainedLevel: 0)
            SkillCell(skill: ECKCharacterSkill.dummy1,
                      trainedLevel: 5)
            SkillCell(skill: ECKCharacterSkill.dummy1,
                      trainedLevel: nil)
            SkillCell(skill: ECKCharacterSkill.dummy2,
                      trainedLevel: 0)
            SkillCell(skill: ECKCharacterSkill.dummy2,
                      trainedLevel: 4)
            SkillCell(skill: ECKCharacterSkill.dummy2,
                      trainedLevel: nil)
        }
    }
}
