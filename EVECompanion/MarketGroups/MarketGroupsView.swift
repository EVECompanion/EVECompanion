//
//  MarketGroupsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 07.04.25.
//

import SwiftUI
import EVECompanionKit

struct MarketGroupsView<LeadingSection>: View where LeadingSection: View {
    
    @StateObject var manager: ECKMarketGroupManager
    
    private var selectionHandler: ((ECKItem) -> Void)?
    private let customTitle: String?
    private let leadingSection: () -> LeadingSection?
    
    init(groupIdFilter: Int?,
         marketGroupIdFilter: Int?,
         effectIdFilter: Int?,
         customTitle: String? = nil,
         leadingSection: @escaping () -> LeadingSection? = { nil },
         selectionHandler: ((ECKItem) -> Void)? = nil) {
        let manager = ECKMarketGroupManager(groupIdFilter: groupIdFilter,
                                            marketGroupIdFilter: marketGroupIdFilter,
                                            effectIdFilter: effectIdFilter)
        self.customTitle = customTitle
        self.selectionHandler = selectionHandler
        self.leadingSection = leadingSection
        self._manager = .init(wrappedValue: manager)
    }
    
    var body: some View {
        List {
            leadingSection()
            
            OutlineGroup(manager.marketGroups, children: \.children) { type in
                switch type {
                case .item(let item):
                    if let selectionHandler {
                        Button {
                            selectionHandler(item)
                        } label: {
                            itemCell(for: item)
                        }

                    } else {
                        NavigationLink(value: AppScreen.item(item)) {
                            itemCell(for: item)
                        }
                    }
                    
                case .marketGroup(let marketGroup):
                    Text(marketGroup.name)
                }
            }
        }
        .searchable(text: $manager.searchString,
                    placement: .navigationBarDrawer)
        .navigationTitle(customTitle ?? "Item Database")
    }
    
    @ViewBuilder
    func itemCell(for item: ECKItem) -> some View {
        HStack {
            ECImage(id: item.typeId,
                    category: .types)
                .frame(width: 40,
                       height: 40)
            
            Text(item.name)
        }
    }
    
}

#Preview {
    NavigationStack {
        MarketGroupsView<EmptyView>(groupIdFilter: nil,
                                    marketGroupIdFilter: nil,
                                    effectIdFilter: nil)
    }
}
