//
//  WalletJournalView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import SwiftUI
import EVECompanionKit

struct WalletJournalView: View {
    
    @ObservedObject var character: ECKCharacter
    
    var body: some View {
        List(character.walletJournal ?? []) { entry in
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
        .refreshable {
            await character.loadWalletJournal()
        }
        .onAppear(perform: {
            Task {
                await character.loadWalletJournal()
            }
        })
        .navigationTitle("Wallet Journal")
        .overlay {
            if (character.walletJournal ?? []).isEmpty && character.walletJournalLoadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Wallet"),
                                 title: "No Wallet Journal Entries",
                                 subtitle: "New wallet journal entries will appear here")
            }
        }
    }
}

#Preview {
    NavigationStack {
        WalletJournalView(character: .dummy)
    }
}
