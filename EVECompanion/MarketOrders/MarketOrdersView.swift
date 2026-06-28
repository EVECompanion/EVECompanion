//
//  MarketOrdersView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

struct MarketOrdersView: View {
    @ObservedObject var manager: ECKMarketOrderManager
    
    var body: some View {
        Group {
            switch manager.marketOrdersLoadingState {
            case .ready,
                 .reloading:
                List {
                    PageLoaderView(pageLoader: manager) { section in
                        Section {
                            if section.orders.isEmpty {
                                Text(section.emptyText)
                            } else {
                                ForEach(section.orders) { order in
                                    MarketOrderCell(order: order)
                                }
                            }
                        } header: {
                            VStack(alignment: .leading) {
                                Text(section.title)
                                
                                if section.orders.isEmpty == false {
                                    Text("Total ISK: \(ECFormatters.iskLong(totalIsk(for: section.orders)))")
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await manager.reload()
                }
                .searchable(text: $manager.searchText,
                            placement: .navigationBarDrawer)
                
            case .loading:
                ProgressView()
                
            case .error(let error):
                ErrorView(error: error) {
                    await manager.loadMarketOrders()
                }
                
            }
        }
        .navigationTitle("Market Orders")
        .overlay {
            if manager.filteredMarketOrders.isEmpty
                && manager.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                && manager.marketOrdersLoadingState == .ready {
                ContentEmptyView(image: Image("Neocom/MarketOrders"),
                                 title: "No Matching Orders",
                                 subtitle: "Adjust your search or filters to see more results")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Order Type", selection: $manager.typeFilter) {
                        ForEach(ECKMarketOrderTypeFilter.allCases) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                } label: {
                    ToolbarMenuIcon(systemImage: "line.3.horizontal.decrease.circle",
                                    activeSystemImage: "line.3.horizontal.decrease.circle.fill",
                                    isActive: manager.typeFilter.isActiveFilter)
                }
                
                Menu {
                    Picker("Sort Orders", selection: $manager.sortOption) {
                        ForEach(ECKMarketOrderSortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                } label: {
                    ToolbarMenuIcon(systemImage: "arrow.up.arrow.down.circle",
                                    activeSystemImage: "arrow.up.arrow.down.circle.fill",
                                    isActive: manager.sortOption.isDefaultSortOption == false)
                }
            }
        }
    }
    
    func totalIsk(for orders: [ECKMarketOrder]) -> Double {
        return orders.reduce(0) { partialResult, order in
            return partialResult + (order.price * Double(order.volumeRemain))
        }
    }
    
}

#Preview("Character") {
    NavigationStack {
        MarketOrdersView(manager: .init(character: .dummy, isPreview: true))
    }
}

#Preview("Corp") {
    NavigationStack {
        MarketOrdersView(manager: .init(corporation: .dummy, isPreview: true))
    }
}
