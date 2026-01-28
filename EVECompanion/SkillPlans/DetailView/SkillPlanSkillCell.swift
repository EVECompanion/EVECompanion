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
    
    let entry: ECKSkillPlanSkillEntry
    
    @EnvironmentObject private var coordinator: Coordinator
    
    var body: some View {
        HStack {
            Image("Neocom/Skills")
                .resizable()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("\(entry.skill.name) \(ECFormatters.skillLevel(level: entry.level))")
                    
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
                }
                
                if let time = entry.skillTime,
                    let earliestFinishDate = entry.earliestFinishDate {
                    Text("\(ECFormatters.remainingTime(remainingTime: time)) (\(ECFormatters.dateFormatter(date: earliestFinishDate)))")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                coordinator.push(screen: .item(entry.skill))
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
        if index < entry.level {
            return Color.blue
        } else if index == entry.level {
            return Color.red
        } else {
            return Color.clear
        }
    }
    
}

#Preview {
    List {
        SkillPlanSkillCell(entry: .dummy)
    }
    .environmentObject(Coordinator(initialScreen: .incursions))
}
