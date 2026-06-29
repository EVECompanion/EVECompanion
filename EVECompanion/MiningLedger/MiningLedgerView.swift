//
//  MiningLedgerView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import SwiftUI
import EVECompanionKit

struct MiningLedgerView: View {

    @StateObject var manager: ECKMiningLedgerManager

    var body: some View {
        Group {
            switch manager.loadingState {
            case .ready,
                .reloading:
                List {
                    PageLoaderView(pageLoader: manager) { daySummary in
                        Section {
                            MiningLedgerDaySummaryCell(summary: daySummary)
                        } header: {
                            MiningLedgerDaySummaryHeader(summary: daySummary)
                        }
                    }
                }
                .refreshable {
                    await manager.loadMiningLedger()
                }

            case .loading:
                ProgressView()

            case .error(let error):
                ErrorView(error: error) {
                    await manager.loadMiningLedger()
                }
            }
        }
        .navigationTitle("Mining Ledger")
        .overlay {
            if manager.elements.isEmpty && manager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/MiningLedger"),
                                 title: "Empty Mining Ledger",
                                 subtitle: "Recent mining activity will appear here")
            }
        }
    }

}

#Preview {
    NavigationStack {
        MiningLedgerView(manager: .init(character: .dummy, isPreview: true))
    }
}
