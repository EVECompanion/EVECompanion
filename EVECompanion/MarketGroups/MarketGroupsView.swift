//
//  MarketGroupsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 07.04.25.
//

import SwiftUI
import EVECompanionKit

struct MarketGroupsView: View {
    
    @StateObject var manager = ECKMarketGroupManager()
    
    var body: some View {
        List {
            OutlineGroup(manager.marketGroups, children: \.children) { type in
                switch type {
                case .item(let item):
                    NavigationLink(value: AppScreen.item(item)) {
                        HStack {
                            ECImage(id: item.typeId,
                                    category: .types)
                                .frame(width: 40,
                                       height: 40)
                            
                            Text(item.name)
                        }
                    }
                case .marketGroup(let marketGroup):
                    Text(marketGroup.name)
                }
            }
        }
        .searchable(text: $manager.searchString,
                    placement: .navigationBarDrawer)
        .navigationTitle("Item Database")
    }
    
}

#Preview {
    NavigationStack {
        MarketGroupsView()
    }
}
