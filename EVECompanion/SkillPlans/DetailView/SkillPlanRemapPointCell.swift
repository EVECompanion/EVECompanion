//
//  SkillPlanRemapPointCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import SwiftUI
import EVECompanionKit

struct SkillPlanRemapPointCell: View {
    
    private let remap: ECKSkillPlanRemap?
    
    init(remap: ECKSkillPlanRemap?) {
        self.remap = remap
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("Neocom/Augmentations")
                    .resizable()
                    .frame(width: 40, height: 40)
                
                Text("Remap Point")
            }
            
            if let remap {
                attributeView(icon: "Attributes/perception",
                              attribute: "Perception",
                              value: remap.perception)
                attributeView(icon: "Attributes/memory",
                              attribute: "Memory",
                              value: remap.memory)
                attributeView(icon: "Attributes/willpower",
                              attribute: "Willpower",
                              value: remap.willpower)
                attributeView(icon: "Attributes/intelligence",
                              attribute: "Intelligence",
                              value: remap.intelligence)
                attributeView(icon: "Attributes/charisma",
                              attribute: "Charisma",
                              value: remap.charisma)
            }
        }
    }
    
    @ViewBuilder
    private func attributeView(icon: String,
                               attribute: String,
                               value: Int) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 40, height: 40)
            Text(attribute)
            
            Spacer()
            
            Text("\(value) Points")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 1) {
                ForEach(1...10, id: \.self) { entry in
                    Rectangle()
                        .fill(entry <= value ? Color.green : Color.gray)
                        .frame(width: 5, height: 20)
                }
            }
        }
    }
    
}

#Preview {
    List {
        SkillPlanRemapPointCell(remap: nil)
        SkillPlanRemapPointCell(remap: .init(charisma: 0,
                                             intelligence: 10,
                                             memory: 0,
                                             perception: 4,
                                             willpower: 0))
    }
}
