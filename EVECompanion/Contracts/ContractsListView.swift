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
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await contractManager.loadContracts()
                }
                
            }
        }
        .navigationTitle("Contracts")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if contractManager.contracts.isEmpty && contractManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Contracts"),
                                 title: "No Contracts",
                                 subtitle: "New contracts will appear here")
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        ContractsListView(contractManager: .init(character: .dummy, isPreview: true))
    }
}
