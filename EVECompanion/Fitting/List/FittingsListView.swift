//
//  FittingsListView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingsListView: View {
    
    enum SheetItem: String, Identifiable {
        
        var id: String {
            return self.rawValue
        }
        
        case shipSelection
        case esiImport
    }
    
    @EnvironmentObject var coordinator: Coordinator
    @StateObject var fittingManager: ECKFittingManager
    @State var presentedSheet: SheetItem?
    
    var body: some View {
        List {
            if fittingManager.localFittings.isEmpty == false {
                Section("Local Fittings") {
                    ForEach(fittingManager.localFittings) { fitting in
                        NavigationLink(value: AppScreen.fittingDetail(fittingManager,
                                                                      fitting)) {
                            FittingCell(fitting: fitting)
                        }
                    }
                }
            }
        }
        .refreshable {
            await fittingManager.loadFittings()
        }
        .searchable(text: $fittingManager.searchText)
        .navigationTitle("Fittings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedSheet = .esiImport
                } label: {
                    Text("Import")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedSheet = .shipSelection
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .shipSelection:
                ShipSelectionView { ship in
                    coordinator.push(screen: .fittingDetail(fittingManager, fittingManager.createFitting(with: ship)))
                }
            case .esiImport:
                FittingESIImportView(fittingManager: .init(character: fittingManager.character,
                                                           isPreview: fittingManager.isPreview)) { fitting in
                    fittingManager.importFitting(fitting)
                }
            }
        }
        .overlay {
            if fittingManager.localFittings.isEmpty {
                ContentEmptyView(image: Image("Neocom/Fitting"),
                                 title: "No Fittings",
                                 subtitle: "New Fittings will appear here.")
            }
        }
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .fittingsList(.init(character: .dummy, isPreview: true)))
}
