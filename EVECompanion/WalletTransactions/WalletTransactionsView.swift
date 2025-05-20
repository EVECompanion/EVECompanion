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
        List(character.walletTransactions ?? []) { entry in
            WalletTransactionCell(entry: entry)
        }
        .refreshable {
            await character.loadWalletTransactions()
        }
        .onAppear(perform: {
            Task {
                await character.loadWalletTransactions()
            }
        })
        .navigationTitle("Wallet Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if (character.walletTransactions ?? []).isEmpty && character.walletTransactionsLoadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Journal"),
                                 title: "No Wallet Transactions",
                                 subtitle: "New wallet transactions will appear here")
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        WalletTransactionsView(character: .dummy)
    }
}
