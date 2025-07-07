//
//  ItemView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 23.03.25.
//

import SwiftUI
import EVECompanionKit

struct ItemView: View {
    let item: ECKItem
    
    var body: some View {
        List {
            ItemViewHeaderSection(item: item)
            
            ForEach(item.bonusTexts, id: \.header) { entry in
                Section {
                    AttributedTextView(entry.text)
                } header: {
                    AttributedTextView(entry.header)
                }
            }
            
            if let skillRequirements = item.skillRequirements,
               skillRequirements.isEmpty == false {
                SkillRequirementsView(item: item)
            }
            
            ForEach(item.itemAttributeCategories, id: \.name) { attributeCategory in
                Section(attributeCategory.name) {
                    ForEach(attributeCategory.attributes, id: \.id) { attribute in
                        ItemAttributeCell(attribute: attribute, fittingAttribute: nil)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(item.name)
    }
}
#Preview("Avatar") {
    NavigationStack {
        ItemView(item: .init(typeId: 11567))
    }
}

#Preview("Avatar Blueprint") {
    NavigationStack {
        ItemView(item: .init(typeId: 11568))
    }
}

#Preview("Hel") {
    NavigationStack {
        ItemView(item: .init(typeId: 22852))
    }
}

#Preview("5MN Microwarpdrive I") {
    NavigationStack {
        ItemView(item: .init(typeId: 434))
    }
}

#Preview("Nova Light Missile") {
    NavigationStack {
        ItemView(item: .init(typeId: 213))
    }
}

#Preview("Shield Recharger I") {
    NavigationStack {
        ItemView(item: .init(typeId: 393))
    }
}

#Preview("Nuclear S") {
    NavigationStack {
        ItemView(item: .init(typeId: 179))
    }
}
