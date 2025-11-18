//
//  ItemMarketDataView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.11.25.
//

import SwiftUI
import EVECompanionKit
import Charts

struct ItemMarketDataView: View {
    
    let history: [ECKMarketHistoryEntry]
    
    var body: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { (_, order) in
                LineMark(
                    x: .value("Date", order.date, unit: .day),
                    y: .value("Price", order.average)
                )
                .foregroundStyle(Color.blue)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                if let price = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(ECFormatters.iskShort(price)) ISK")
                    }
                    
                    AxisGridLine()
                }
            }
        }
        .frame(height: 250)
        
    }
    
}

#Preview {
    ItemView(item: .init(typeId: 434))
}
