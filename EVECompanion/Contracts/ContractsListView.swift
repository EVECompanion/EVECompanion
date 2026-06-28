//
//  ContractsListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.05.24.
//

import SwiftUI
import EVECompanionKit

struct ContractsListView: View {
    @StateObject var contractManager: ECKContractManager
    
    var body: some View {
        Group {
            switch contractManager.loadingState {
            case .ready,
                 .reloading:
                List {
                    PageLoaderView(pageLoader: contractManager) { section in
                        Section(section.title) {
                            ForEach(section.contracts) { contract in
                                ContractListCell(contract: contract)
                            }
                        }
                    }
                }
                .refreshable {
                    await contractManager.reload()
                }
                .searchable(text: $contractManager.searchText,
                            placement: .navigationBarDrawer)
                
            case .loading:
                ProgressView()
                
            case .error(let error):
                ErrorView(error: error) {
                    await contractManager.loadContracts()
                }
                
            }
        }
        .navigationTitle("Contracts")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Picker("Status", selection: $contractManager.statusFilter) {
                        ForEach(ECKContractStatusFilter.allCases) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                    
                    Picker("Type", selection: $contractManager.typeFilter) {
                        ForEach(ECKContractTypeFilter.allCases) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                } label: {
                    ToolbarMenuIcon(systemImage: "line.3.horizontal.decrease.circle",
                                    activeSystemImage: "line.3.horizontal.decrease.circle.fill",
                                    isActive: hasActiveFilter)
                }
                
                Menu {
                    Picker("Sort Contracts", selection: $contractManager.sortOption) {
                        ForEach(ECKContractSortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                } label: {
                    ToolbarMenuIcon(systemImage: "arrow.up.arrow.down.circle",
                                    activeSystemImage: "arrow.up.arrow.down.circle.fill",
                                    isActive: contractManager.sortOption.isDefaultSortOption == false)
                }
            }
        }
        .overlay {
            if contractManager.contracts.isEmpty && contractManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Contracts"),
                                 title: "No Contracts",
                                 subtitle: "New contracts will appear here")
            } else if contractManager.filteredContracts.isEmpty && contractManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Contracts"),
                                 title: "No Matching Contracts",
                                 subtitle: "Adjust your filters or search to see more results")
            }
        }
    }

    private var hasActiveFilter: Bool {
        contractManager.statusFilter.isActiveFilter
        || contractManager.typeFilter.isActiveFilter
    }

}

#Preview {
    NavigationStack {
        ContractsListView(contractManager: .init(character: .dummy, isPreview: true))
    }
}
