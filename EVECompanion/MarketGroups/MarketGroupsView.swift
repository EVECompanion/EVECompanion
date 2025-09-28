//
//  MarketGroupsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 07.04.25.
//

import SwiftUI
import EVECompanionKit

struct MarketGroupsView: View {
    
    @StateObject var manager: ECKMarketGroupManager
    
    private var selectionHandler: ((ECKItem) -> Void)?
    private let customTitle: String?
    
    init(groupIdFilter: Int?,
         marketGroupIdFilter: Int?,
         customTitle: String? = nil,
         selectionHandler: ((ECKItem) -> Void)? = nil) {
        let manager = ECKMarketGroupManager(groupIdFilter: groupIdFilter,
                                            marketGroupIdFilter: marketGroupIdFilter)
        self.customTitle = customTitle
        self.selectionHandler = selectionHandler
        self._manager = .init(wrappedValue: manager)
    }
    
    var body: some View {
        List {
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
        MarketGroupsView(groupIdFilter: nil,
                         marketGroupIdFilter: nil)
    }
}
