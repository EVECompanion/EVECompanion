//
//  IndustryJobCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import SwiftUI
import EVECompanionKit

struct IndustryJobCell: View {
    
    @ObservedObject var job: ECKIndustryJob
    
    var body: some View {
        if let product = job.product {
            NavigationLink(value: AppScreen.item(product)) {
                contentView
            }
        } else {
            contentView
        }
    }
    
    var contentView: some View {
        HStack {
            if let productId = job.product?.typeId {
                ECImage(id: productId,
                        category: .types)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading) {
                Text("\(job.activity.name)")
                    .font(.headline)
                
                if let product = job.product {
                    Text(product.name)
                }
                
                Spacer()
                    .frame(height: 10)
                
                if job.status == .paused {
                    Text("Paused")
                        .font(.headline)
                } else {
                    ProgressView(value: abs(Double(job.duration) - Date().distance(to: job.endDate)),
                                 total: TimeInterval(job.duration))
                    Text("Completes: \(ECFormatters.dateFormatter(date: job.endDate))")
                }
                
                Text("Runs: \(job.runs)")
                
                Spacer()
                    .frame(height: 10)
                
                Text(job.station.stationName ?? "")
            }
        }
        .animation(.spring, value: job.station.stationName)
    }
    
}

#Preview {
    NavigationStack {
        List {
            IndustryJobCell(job: .dummyActive)
            IndustryJobCell(job: .dummyPaused)
        }
    }
}
