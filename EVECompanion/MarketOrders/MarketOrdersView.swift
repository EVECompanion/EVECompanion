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
    
    var sellOrders: [ECKMarketOrder] {
        manager.sellOrders
    }
    
    var buyOrders: [ECKMarketOrder] {
        manager.buyOrders
    }
    
    var body: some View {
        Group {
            switch manager.marketOrdersLoadingState {
            case .ready,
                 .reloading:
                List {
                    if manager.typeFilter != .buy {
                        Section {
                            if sellOrders.isEmpty {
                                Text("No sell orders")
                            } else {
                                ForEach(sellOrders) { order in
                                    MarketOrderCell(order: order)
                                }
                            }
                        } header: {
                            VStack(alignment: .leading) {
                                Text("Sell Orders")
                                
                                if sellOrders.isEmpty == false {
                                    Text("Total ISK: \(ECFormatters.iskLong(totalIsk(for: sellOrders)))")
                                }
                            }
                        }
                    }
                    
                    if manager.typeFilter != .sell {
                        Section {
                            if buyOrders.isEmpty {
                                Text("No buy orders")
                            } else {
                                ForEach(buyOrders) { order in
                                    MarketOrderCell(order: order)
                                }
                            }
                        } header: {
                            VStack(alignment: .leading) {
                                Text("Buy Orders")
                                
                                if buyOrders.isEmpty == false {
                                    Text("Total ISK: \(ECFormatters.iskLong(totalIsk(for: buyOrders)))")
                                }
                            }
                        }
                    }
                }
                .refreshable {
                    await manager.loadMarketOrders()
                }
                .searchable(text: $manager.searchText,
                            placement: .navigationBarDrawer)
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await manager.loadMarketOrders()
                }
                
            }
        }
        .onAppear(perform: {
            Task {
                await manager.loadMarketOrders()
            }
        })
        .navigationTitle("Market Orders")
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
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Menu {
                    Picker("Sort Orders", selection: $manager.sortOption) {
                        ForEach(ECKMarketOrderSortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
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
