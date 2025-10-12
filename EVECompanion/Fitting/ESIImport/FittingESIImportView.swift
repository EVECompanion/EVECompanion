//
//  FittingESIImportView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 30.09.25.
//

import SwiftUI
import EVECompanionKit

struct FittingESIImportView: View {
    
    let doneHandler: (ECKCharacterFitting) -> Void
    @StateObject var fittingManager: ECKESIFittingManager
    @Environment(\.dismiss) var dismiss
    
    init(fittingManager: ECKESIFittingManager,
         doneHandler: @escaping (ECKCharacterFitting) -> Void) {
        self._fittingManager = .init(wrappedValue: fittingManager)
        self.doneHandler = doneHandler
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch fittingManager.esiLoadingState {
                case .ready,
                     .reloading:
                    List(fittingManager.esiFittings) { fitting in
                        Button {
                            doneHandler(fitting)
                            dismiss()
                        } label: {
                            FittingCell(fitting: fitting)
                        }
                        .buttonStyle(.plain)
                    }
                    .refreshable {
                        await fittingManager.loadFittings()
                    }
                    .searchable(text: $fittingManager.searchText)
                    
                case .loading:
                    ProgressView()
                    
                case .error:
                    RetryButton {
                        await fittingManager.loadFittings()
                    }
                    
                }
            }
            .navigationTitle("Select Fitting to Import")
            .overlay {
                if fittingManager.esiFittings.isEmpty &&
                    fittingManager.esiLoadingState == .ready {
                    ContentEmptyView(image: Image("Neocom/Fitting"),
                                     title: "No EVE Fittings",
                                     subtitle: "New Fittings you saved in EVE will appear here.")
                }
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            FittingESIImportView(fittingManager: .init(character: .dummy, isPreview: true)) { _ in
                return
            }
        }
}
