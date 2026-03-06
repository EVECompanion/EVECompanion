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
    let selectionHandler: (ECKItem) -> Void
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
                            Button {
                                selectionHandler(item)
                            } label: {
                                itemCell(for: item, currentLevel: currentSkills.skillLevel(typeId: item.typeId))
                            }
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
    
    @ViewBuilder
    func itemCell(for item: ECKItem, currentLevel: ECKCharacterSkillLevel?) -> some View {
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
                                    indicatorColor(for: index, skillLevel: currentLevel?.trainedSkillLevel ?? 0)
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
    
    private func indicatorColor(for index: Int, skillLevel: Int) -> Color {
        if index <= skillLevel {
            return Color.blue
        } else {
            return Color.clear
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SkillPlanSelectionView(currentSkills: .dummy) { _ in
                return
            }
        }
}
