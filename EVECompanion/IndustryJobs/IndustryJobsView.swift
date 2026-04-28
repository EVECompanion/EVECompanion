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
                List {
                    PageLoaderView(pageLoader: industryJobsManager) { job in
                        IndustryJobCell(job: job)
                    }
                }
                .refreshable {
                    await industryJobsManager.loadJobs()
                }
                
            case .loading:
                ProgressView()
                
            case .error(let error):
                ErrorView(error: error) {
                    await industryJobsManager.loadJobs()
                }
                
            }
        }
        .navigationTitle("Industry Jobs")
        .overlay {
            if industryJobsManager.elements.isEmpty && industryJobsManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Industry"),
                                 title: "No Industry Jobs",
                                 subtitle: "New industry jobs will appear here")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Activity", selection: $industryJobsManager.activityFilter) {
                        ForEach(ECKIndustryJobManager.ActivityFilter.allCases) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Menu {
                    Picker("Sort Contracts", selection: $industryJobsManager.sortOption) {
                        ForEach(ECKIndustryJobManager.SortOption.allCases) { option in
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
    
}

#Preview {
    NavigationView {
        IndustryJobsView(industryJobsManager: .init(character: .dummy,
                                                    isPreview: true))
    }
}
