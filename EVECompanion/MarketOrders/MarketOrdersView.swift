//
//  MarketOrdersView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

struct MarketOrdersView: View {
    
    @ObservedObject var character: ECKCharacter
    
    var sellOrders: [ECKMarketOrder] {
        return (character.marketOrders ?? []).filter({ $0.isBuyOrder == false })
    }
    
    var buyOrders: [ECKMarketOrder] {
        return (character.marketOrders ?? []).filter({ $0.isBuyOrder })
    }
    
    var body: some View {
        Group {
            switch character.marketOrdersLoadingState {
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
                    await character.loadMarketOrders()
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await character.loadMarketOrders()
                }
                
            }
        }
        .onAppear(perform: {
            Task {
                await character.loadMarketOrders()
            }
        })
        .navigationTitle("Market Orders")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func totalIsk(for orders: [ECKMarketOrder]) -> Double {
        return orders.reduce(0) { partialResult, order in
            return partialResult + (order.price * Double(order.volumeRemain))
        }
    }
    
}

#Preview {
    NavigationStack {
        MarketOrdersView(character: .dummy)
    }
}
