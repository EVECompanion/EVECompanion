//
//  WalletJournalView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import SwiftUI
import EVECompanionKit

struct WalletJournalView: View {
    
    @StateObject var walletJournalManager: ECKWalletJournalManager
    
    var body: some View {
        switch walletJournalManager.loadingState {
        case .ready, .reloading, .error:
            List {
                walletDivisionPicker
                
                if walletJournalManager.entries.isEmpty && walletJournalManager.loadingState == .ready {
                    Section {
                        ContentEmptyView(image: Image("Neocom/Wallet"),
                                         title: "No Wallet Journal Entries",
                                         subtitle: "New wallet journal entries will appear here")
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } else if walletJournalManager.filteredEntries.isEmpty, case .error(let error) = walletJournalManager.loadingState {
                    ErrorView(error: error) {
                        await walletJournalManager.loadWalletJournal(forceReload: true)
                    }
                } else if walletJournalManager.filteredEntries.isEmpty {
                    Section {
                        ContentEmptyView(image: Image("Neocom/Wallet"),
                                         title: "No Results",
                                         subtitle: "Try adjusting your filters or search")
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } else {
                    PageLoaderView(pageLoader: walletJournalManager) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(entry.description)
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    if let balance = entry.balance {
                                        Text("Balance: \(ECFormatters.iskShort(balance)) ISK")
                                    }
                                    
                                    Text(ECFormatters.dateFormatter(date: entry.date))
                                }
                                
                                Spacer()
                                
                                if let amount = entry.amount {
                                    Text(ECFormatters.iskLong(amount) + " ISK")
                                        .foregroundStyle(amount < 0 ? Color.red : Color.green)
                                }
                            }
                            
                            if let reason = entry.reason,
                               reason.isEmpty == false {
                                Text(reason)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await walletJournalManager.reload()
            }
            .navigationTitle("Wallet Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $walletJournalManager.amountFilter) {
                            ForEach(ECKWalletJournalAmountFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                walletJournalManager.selectDefaultDivisionIfNeeded()
            }
            .onChange(of: walletJournalManager.selectedDivisionId) { _ in
                Task<Void, Never> {
                    await walletJournalManager.loadWalletJournal()
                }
            }
        case .loading:
            ProgressView()
        }
    }
    
    @ViewBuilder
    private var walletDivisionPicker: some View {
        if walletJournalManager.walletDivisions.isEmpty == false {
            Picker("Wallet Division", selection: selectedDivisionIdBinding) {
                ForEach(walletJournalManager.walletDivisions) { division in
                    Text(division.name)
                        .tag(division.division)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    private var selectedDivisionIdBinding: Binding<Int?> {
        Binding(
            get: {
                walletJournalManager.selectedDivision?.division
            },
            set: { newValue in
                walletJournalManager.selectDivision(id: newValue)
            }
        )
    }
}

#Preview {
    NavigationStack {
        WalletJournalView(walletJournalManager: .init(character: .dummy, isPreview: true))
    }
}
