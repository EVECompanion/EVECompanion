//
//  MarketOrderCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

struct MarketOrderCell: View {
    
    let order: ECKMarketOrder
    
    var body: some View {
        NavigationLink(value: AppScreen.item(order.item)) {
            HStack {
                ECImage(id: order.item.typeId,
                        category: .types)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(order.item.name)
                        .font(.headline)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("Price: \(ECFormatters.iskLong(order.price))")
                    Text("Quantity: \(order.volumeRemain)/\(order.volumeTotal)")
                    Text("Issued: \(ECFormatters.dateFormatter(date: order.issued))")
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text(order.station.stationName ?? "")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            MarketOrderCell(order: .dummy1)
            MarketOrderCell(order: .dummy2)
        }
    }
}
