//
//  SkillPlanSkillCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import Foundation
import SwiftUI
import EVECompanionKit

struct SkillPlanSkillCell: View {
    
    let skill: ECKItem
    let skillLevel: Int
    
    @EnvironmentObject private var coordinator: Coordinator
    
    var body: some View {
        HStack {
            Image("Neocom/Skills")
                .resizable()
                .frame(width: 40, height: 40)
            
            Text("\(skill.name) \(ECFormatters.skillLevel(level: skillLevel))")
            
            Spacer()
            
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .background {
                            indicatorColor(for: index)
                        }
                }
            }
            
            Button {
                coordinator.push(screen: .item(skill))
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
    }
    
    private func indicatorColor(for index: Int) -> Color {
        if index < skillLevel {
            return Color.blue
        } else if index == skillLevel {
            return Color.red
        } else {
            return Color.clear
        }
    }
    
}

#Preview {
    List {
        SkillPlanSkillCell(skill: .init(typeId: 27906), skillLevel: 4)
    }
    .environmentObject(Coordinator(initialScreen: .incursions))
}
