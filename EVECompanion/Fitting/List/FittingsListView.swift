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
    
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var fittingManager: ECKFittingManager
    @State private var presentedSheet: SheetItem?
    
    @State private var fittingToRename: ECKCharacterFitting?
    @State private var showChangeNameAlert: Bool = false
    @State private var changeNameInput: String = ""
    
    init(fittingManager: ECKFittingManager) {
        self._fittingManager = .init(wrappedValue: fittingManager)
    }
    
    var body: some View {
        List {
            if fittingManager.localFittings.isEmpty == false {
                ForEach(fittingManager.localFittings) { fitting in
                    NavigationLink(value: AppScreen.fittingDetail(fittingManager,
                                                                  fitting)) {
                        FittingCell(fitting: fitting)
                            .contextMenu {
                                Button {
                                    fittingToRename = fitting
                                    showChangeNameAlert = true
                                } label: {
                                    Label {
                                        Text("Change Name")
                                    } icon: {
                                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    }
                                }
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
        .alert("Fit Name",
               isPresented: $showChangeNameAlert,
               presenting: fittingToRename,
               actions: { fitting in
            TextField("Fit Name", text: $changeNameInput)
                .onAppear {
                    changeNameInput = fitting.name
                }
            
            Button {
                fitting.setName(changeNameInput, manager: fittingManager)
            } label: {
                Text("Ok")
            }
            
            Button(role: .cancel) {
                changeNameInput = fitting.name
            } label: {
                Text("Cancel")
            }
        })
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
