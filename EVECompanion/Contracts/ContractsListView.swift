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
                    if contractManager.outstandingContracts.isEmpty == false {
                        Section("Outstanding") {
                            ForEach(contractManager.outstandingContracts) { contract in
                                ContractListCell(contract: contract)
                            }
                        }
                    }
                    
                    if contractManager.inProgressContracts.isEmpty == false {
                        Section("In Progress") {
                            ForEach(contractManager.inProgressContracts) { contract in
                                ContractListCell(contract: contract)
                            }
                        }
                    }
                    
                    if contractManager.failedContracts.isEmpty == false {
                        Section("Failed") {
                            ForEach(contractManager.failedContracts) { contract in
                                ContractListCell(contract: contract)
                            }
                        }
                    }
                    
                    if contractManager.finishedContracts.isEmpty == false {
                        Section("Finished") {
                            ForEach(contractManager.finishedContracts) { contract in
                                ContractListCell(contract: contract)
                            }
                        }
                    }
                }
                .refreshable {
                    await contractManager.loadContracts()
                }
                .searchable(text: $contractManager.searchText,
                            placement: .navigationBarDrawer)
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
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
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Menu {
                    Picker("Sort Contracts", selection: $contractManager.sortOption) {
                        ForEach(ECKContractSortOption.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
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
}

#Preview {
    NavigationStack {
        ContractsListView(contractManager: .init(character: .dummy, isPreview: true))
    }
}
