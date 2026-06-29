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
    
    private var activityColor: Color {
        guard let color = job.activity.jobType?.color else {
            return .primary
        }
        
        return Color(uiColor: color)
    }
    
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
                HStack(spacing: 6) {
                    Circle()
                        .fill(activityColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(job.activity.name)")
                        .font(.headline)
                        .foregroundStyle(activityColor)
                }
                
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
                        .tint(activityColor)
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
            ForEach(ECKIndustryJob.dummyJobs) { job in
                IndustryJobCell(job: job)
            }
        }
    }
}
