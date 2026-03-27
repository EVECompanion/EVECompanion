//
//  MarketOrdersView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

protocol MarketOrdersViewSource: ObservableObject {
    var marketOrders: [ECKMarketOrder]? { get }
    var marketOrdersLoadingState: ECKLoadingState { get }
    func loadMarketOrders() async
}

extension ECKCharacter: MarketOrdersViewSource { }
extension ECKAuthenticatedCorporation: MarketOrdersViewSource { }

struct MarketOrdersView<Source: MarketOrdersViewSource>: View {
    
    @ObservedObject private var source: Source
    
    init(source: Source) {
        self.source = source
    }
    
    var sellOrders: [ECKMarketOrder] {
        return (source.marketOrders ?? []).filter({ $0.isBuyOrder == false })
    }
    
    var buyOrders: [ECKMarketOrder] {
        return (source.marketOrders ?? []).filter({ $0.isBuyOrder })
    }
    
    var body: some View {
        Group {
            switch source.marketOrdersLoadingState {
            case .ready,
                 .reloading:
                List {
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
                .refreshable {
                    await source.loadMarketOrders()
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await source.loadMarketOrders()
                }
                
            }
        }
        .onAppear(perform: {
            Task {
                await source.loadMarketOrders()
            }
        })
        .navigationTitle("Market Orders")
    }
    
    func totalIsk(for orders: [ECKMarketOrder]) -> Double {
        return orders.reduce(0) { partialResult, order in
            return partialResult + (order.price * Double(order.volumeRemain))
        }
    }
    
}

#Preview("Character") {
    NavigationStack {
        MarketOrdersView(source: ECKCharacter.dummy)
    }
}

#Preview("Corp") {
    NavigationStack {
        MarketOrdersView(source: ECKAuthenticatedCorporation.dummy)
    }
}
