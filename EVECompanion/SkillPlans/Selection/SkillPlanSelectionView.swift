//
//  SkillPlanSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.11.25.
//

import SwiftUI
import EVECompanionKit

struct SkillPlanSelectionView: View {
    
    let selectionHandler: (ECKItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            MarketGroupsView<EmptyView, EmptyView>(groupIdFilter: nil,
                                                   marketGroupIdFilter: 150,
                                                   effectIdFilter: nil,
                                                   customTitle: "Choose Skill to Train",
                                                   selectionHandler: { selection in
                selectionHandler(selection)
                dismiss()
            })
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SkillPlanSelectionView { _ in
                return
            }
        }
}
