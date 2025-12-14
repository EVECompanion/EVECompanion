//
//  SkillPlanListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import SwiftUI
import EVECompanionKit

struct SkillPlanListView: View {
    
    @ObservedObject private var manager: ECKSkillPlanManager
    @EnvironmentObject private var coordinator: Coordinator
    
    init(manager: ECKSkillPlanManager) {
        self.manager = manager
    }
    
    var body: some View {
        List {
            ForEach(manager.skillPlans) { skillPlan in
                NavigationLink(value: AppScreen.skillPlanDetail(skillPlan, manager)) {
                    Text(skillPlan.name)
                }
            }
            .onDelete { indicesToDelete in
                if let indexToDelete = indicesToDelete.first {
                    manager.deleteSkillPlan(manager.skillPlans[indexToDelete])
                }
            }
        }
        .navigationTitle("Skill Plans")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let newSkillPlan = manager.createSkillPlan()
                    coordinator.push(screen: .skillPlanDetail(newSkillPlan, manager))
                } label: {
                    Image(systemName: "plus")
                }

            }
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .skillPlanList(.init(character: .dummy, isPreview: true)))
}
