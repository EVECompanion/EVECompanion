//
//  IndustryJobsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 18.06.24.
//

import SwiftUI
import EVECompanionKit

struct IndustryJobsView: View {
    
    @StateObject var industryJobsManager: ECKIndustryJobManager
    
    var body: some View {
        Group {
            switch industryJobsManager.loadingState {
            case .ready,
                 .reloading:
                List(industryJobsManager.jobs) { job in
                    IndustryJobCell(job: job)
                }
                .refreshable {
                    await industryJobsManager.loadJobs()
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await industryJobsManager.loadJobs()
                }
                
            }
        }
        .navigationTitle("Industry Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if industryJobsManager.jobs.isEmpty && industryJobsManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Industry"),
                                 title: "No Industry Jobs",
                                 subtitle: "New industry jobs will appear here")
            }
        }
    }
    
}

#Preview {
    NavigationView {
        IndustryJobsView(industryJobsManager: .init(character: .dummy,
                                                    isPreview: true))
    }
}
