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
    
    var body: some View {
        Group {
            switch character.marketOrdersLoadingState {
            case .ready,
                 .reloading:
                List {
                    
                    Section("Sell Orders") {
                        if (character.marketOrders ?? []).filter({ $0.isBuyOrder == false }).isEmpty {
                            Text("No sell orders")
                        } else {
                            ForEach((character.marketOrders ?? []).filter({ $0.isBuyOrder == false })) { order in
                                MarketOrderCell(order: order)
                            }
                        }
                    }
                    
                    Section("Buy Orders") {
                        if (character.marketOrders ?? []).filter({ $0.isBuyOrder }).isEmpty {
                            Text("No buy orders")
                        } else {
                            ForEach((character.marketOrders ?? []).filter({ $0.isBuyOrder })) { order in
                                MarketOrderCell(order: order)
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
    
}

#Preview {
    NavigationStack {
        MarketOrdersView(character: .dummy)
    }
}
