//
//  SkillCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit

struct SkillCell: View {
    
    let level: ECKCharacterSkillLevel
    
    var body: some View {
        HStack {
            Text("\(level.skill.name) \(ECFormatters.skillLevel(level: level.trainedSkillLevel))")
            
            Spacer()
            
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(index <= level.trainedSkillLevel ? Color.blue : Color.clear)
                }
            }
        }
    }
}

#Preview {
    List {
        Section("Spaceship Command") {
            SkillCell(level: .dummy1)
            SkillCell(level: .dummy2)
        }
    }
}
