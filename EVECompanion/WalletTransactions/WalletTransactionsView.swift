//
//  WalletTransactionsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import EVECompanionKit

struct WalletTransactionsView: View {
    
    @ObservedObject var character: ECKCharacter
    
    var body: some View {
        WalletTransactionsListView(
            entries: character.walletTransactions ?? [],
            loadingState: character.walletTransactionsLoadingState,
            title: "Wallet Transactions",
            load: {
                await character.loadWalletTransactions()
            },
            header: { }
        )
    }
    
}

struct CorporationWalletTransactionsView: View {
    
    @ObservedObject var corporation: ECKAuthenticatedCorporation
    @State private var selectedDivisionId: Int?
    
    private var selectedDivision: ECKCorporationWalletDivision? {
        guard let walletDivisions = corporation.walletDivisions,
              walletDivisions.isEmpty == false else {
            return nil
        }
        
        return walletDivisions.first(where: { $0.division == selectedDivisionId }) ?? walletDivisions.first
    }
    
    var body: some View {
        WalletTransactionsListView(
            entries: selectedDivision.flatMap { corporation.walletTransactions(for: $0) } ?? [],
            loadingState: selectedDivision.map { corporation.walletTransactionsLoadingState(for: $0) } ?? .loading,
            title: "Wallet Transactions",
            load: {
                guard let selectedDivision else {
                    await corporation.loadWalletDivisions()
                    return
                }
                
                await corporation.loadWalletTransactions(for: selectedDivision)
            },
            header: {
                walletDivisionPicker
            }
        )
        .onAppear {
            selectDefaultDivisionIfNeeded()
        }
        .onChange(of: corporation.walletDivisions?.map(\.division) ?? []) { _ in
            selectDefaultDivisionIfNeeded()
        }
        .onChange(of: selectedDivisionId) { _ in
            Task<Void, Never> {
                guard let selectedDivision else {
                    return
                }
                
                await corporation.loadWalletTransactions(for: selectedDivision)
            }
        }
    }
    
    @ViewBuilder
    private var walletDivisionPicker: some View {
        if let walletDivisions = corporation.walletDivisions,
           walletDivisions.isEmpty == false {
            Picker("Wallet Division", selection: selectedDivisionIdBinding) {
                ForEach(walletDivisions) { division in
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
                selectedDivision?.division
            },
            set: { newValue in
                selectedDivisionId = newValue
            }
        )
    }
    
    private func selectDefaultDivisionIfNeeded() {
        guard selectedDivisionId == nil else {
            return
        }
        
        selectedDivisionId = corporation.walletDivisions?.first?.division
    }
    
}

private struct WalletTransactionsListView<Header: View>: View {
    
    let entries: [ECKWalletTransactionEntry]
    let loadingState: ECKLoadingState
    let title: String
    let load: () async -> Void
    let header: Header
    
    init(entries: [ECKWalletTransactionEntry],
         loadingState: ECKLoadingState,
         title: String,
         load: @escaping () async -> Void,
         @ViewBuilder header: () -> Header) {
        self.entries = entries
        self.loadingState = loadingState
        self.title = title
        self.load = load
        self.header = header()
    }
    
    var body: some View {
        List {
            header
            
            if entries.isEmpty && loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Journal"),
                                 title: "No Wallet Transactions",
                                 subtitle: "New wallet transactions will appear here")
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(entries) { entry in
                    WalletTransactionCell(entry: entry)
                }
            }
        }
        .refreshable {
            await load()
        }
        .onAppear {
            Task<Void, Never> {
                await load()
            }
        }
        .navigationTitle(title)
    }
    
}

#Preview {
    NavigationStack {
        WalletTransactionsView(character: .dummy)
    }
}
