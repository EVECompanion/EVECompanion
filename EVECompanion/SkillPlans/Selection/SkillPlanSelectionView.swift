//
//  SkillPlanSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import SwiftUI
import EVECompanionKit

struct SkillPlanSelectionView: View {
    
    let currentSkills: ECKCharacterSkills
    @ObservedObject var skillPlan: ECKSkillPlan
    let selectionHandler: (ECKItem, Int?) -> Void
    @StateObject private var manager: ECKMarketGroupManager = .init(
        groupIdFilter: nil,
        marketGroupIdFilter: 150,
        effectIdFilter: nil
    )
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    OutlineGroup(manager.marketGroups, children: \.children) { type in
                        switch type {
                        case .item(let item):
                            itemButton(
                                for: item,
                                currentLevel: currentLevel(typeId: item.typeId)
                            )
                            .disabled(canAddSkill(typeId: item.typeId) == false)
                            .buttonStyle(.plain)
                            
                        case .marketGroup(let marketGroup):
                            Text(marketGroup.name)
                        }
                    }
                }
            }
            .searchable(text: $manager.searchString)
            .navigationTitle("Choose Skills to Train")
        }
    }
    
    func canAddSkill(typeId: Int) -> Bool {
        guard let currentLevel = currentSkills.skillLevel(typeId: typeId) else {
            return true
        }
        
        return currentLevel.trainedSkillLevel < 5
    }
    
    func trainedLevel(typeId: Int) -> Int? {
        currentSkills.skillLevel(typeId: typeId)?.trainedSkillLevel
    }
    
    func plannedLevel(typeId: Int) -> Int? {
        skillPlan.entries.filter({ $0.skill?.skill.id == typeId }).compactMap({ $0.skill?.level }).max()
    }
    
    func currentLevel(typeId: Int) -> Int? {
        let trainedLevel = trainedLevel(typeId: typeId)
        let plannedLevel = plannedLevel(typeId: typeId)
        
        if let plannedLevel, let trainedLevel {
            return max(trainedLevel, plannedLevel)
        } else if let plannedLevel {
            return plannedLevel
        } else if let trainedLevel {
            return trainedLevel
        } else {
            return nil
        }
    }
    
    @ViewBuilder
    func itemButton(for item: ECKItem, currentLevel: Int?) -> some View {
        if currentLevel ?? 0 < 5 {
            Menu {
                ForEach(((currentLevel ?? 0) + 1)...5, id: \.self) { level in
                    Button {
                        selectionHandler(item, level)
                    } label: {
                        Text("Train to \(level)")
                    }
                }
            } label: {
                skillCell(for: item, currentLevel: currentLevel)
            }
        } else {
            skillCell(for: item, currentLevel: currentLevel)
        }
    }
    
    @ViewBuilder
    private func skillCell(for item: ECKItem, currentLevel: Int?) -> some View {
        HStack {
            ECImage(id: item.typeId,
                    category: .types)
            .frame(width: 40,
                   height: 40)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                    
                    HStack(spacing: 5) {
                        ForEach(1...5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.primary, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .background {
                                    indicatorColor(
                                        for: index,
                                        skillLevel: currentLevel ?? 0,
                                        trainedLevel: trainedLevel(typeId: item.typeId),
                                        plannedLevel: plannedLevel(typeId: item.typeId)
                                    )
                                }
                        }
                    }
                }
                
                Spacer()
                
                if currentLevel == nil {
                    Text("Not injected")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        }
    }
    
    private func indicatorColor(for index: Int, skillLevel: Int, trainedLevel: Int?, plannedLevel: Int?) -> Color {
        if index <= skillLevel {
            if let trainedLevel, trainedLevel >= index {
                return Color.blue
            } else if let plannedLevel, plannedLevel >= index {
                return Color.green
            } else {
                return Color.blue
            }
        } else {
            return Color.clear
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SkillPlanSelectionView(currentSkills: .dummy, skillPlan: .dummy) { _, _ in
                return
            }
        }
}
