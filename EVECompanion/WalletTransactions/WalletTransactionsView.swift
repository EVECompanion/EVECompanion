//
//  WalletTransactionsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit

struct WalletTransactionsView: View {
    
    @StateObject var walletTransactionManager: ECKWalletTransactionManager
    
    var body: some View {
        WalletTransactionsListView(
            manager: walletTransactionManager,
            loadingState: walletTransactionManager.loadingState,
            load: {
                await walletTransactionManager.loadWalletTransactions()
            },
            reload: {
                await walletTransactionManager.reload()
            },
            header: { }
        )
    }
    
}

struct CorporationWalletTransactionsView: View {
    
    @StateObject var walletTransactionManager: ECKWalletTransactionManager
    
    var body: some View {
        WalletTransactionsListView(
            manager: walletTransactionManager,
            loadingState: walletTransactionManager.loadingState,
            load: {
                await walletTransactionManager.loadWalletTransactions()
            },
            reload: {
                await walletTransactionManager.reload()
            },
            header: {
                walletDivisionPicker
            }
        )
        .onAppear {
            walletTransactionManager.selectDefaultDivisionIfNeeded()
        }
        .onChange(of: walletTransactionManager.selectedDivisionId) { _ in
            Task<Void, Never> {
                await walletTransactionManager.loadWalletTransactions()
            }
        }
    }
    
    @ViewBuilder
    private var walletDivisionPicker: some View {
        if walletTransactionManager.walletDivisions.isEmpty == false {
            Picker("Wallet Division", selection: selectedDivisionIdBinding) {
                ForEach(walletTransactionManager.walletDivisions) { division in
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
                walletTransactionManager.selectedDivision?.division
            },
            set: { newValue in
                walletTransactionManager.selectDivision(id: newValue)
            }
        )
    }
    
}

private struct WalletTransactionsListView<Header: View>: View {
    
    @ObservedObject var manager: ECKWalletTransactionManager
    let loadingState: ECKLoadingState
    let load: () async -> Void
    let reload: () async -> Void
    let header: Header
    
    init(manager: ECKWalletTransactionManager,
         loadingState: ECKLoadingState,
         load: @escaping () async -> Void,
         reload: @escaping () async -> Void,
         @ViewBuilder header: () -> Header) {
        self.manager = manager
        self.loadingState = loadingState
        self.load = load
        self.reload = reload
        self.header = header()
    }
    
    var body: some View {
        switch loadingState {
        case .ready,
                .reloading,
                .error:
            List {
                header
                
                if manager.walletTransactions.isEmpty && loadingState == .ready {
                    Section {
                        ContentEmptyView(image: Image("Neocom/Journal"),
                                         title: "No Wallet Transactions",
                                         subtitle: "New wallet transactions will appear here")
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } else if manager.walletTransactions.isEmpty, case .error(let error) = loadingState {
                    ErrorView(error: error) {
                        await reload()
                    }
                } else {
                    PageLoaderView(pageLoader: manager) { entry in
                        WalletTransactionCell(entry: entry)
                    }
                }
            }
            .refreshable {
                await reload()
            }
            .navigationTitle("Wallet Transactions")
        case .loading:
            ProgressView()
        }
    }
    
}

#Preview {
    NavigationStack {
        WalletTransactionsView(walletTransactionManager: .init(character: .dummy, isPreview: true))
    }
}
