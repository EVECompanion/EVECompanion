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
    
    enum AlertItem: Identifiable {
        case renameFit(ECKCharacterFitting)
        case deleteFit(ECKCharacterFitting)
        
        var id: String {
            switch self {
            case .renameFit(let fitting):
                return "renameFit-\(fitting.id)"
            case .deleteFit(let fitting):
                return "deleteFit-\(fitting.id)"
            }
        }
        
        var title: String {
            switch self {
            case .renameFit:
                return "Rename Fit"
            case .deleteFit:
                return "Delete Fit"
            }
        }
    }
    
    @EnvironmentObject private var coordinator: Coordinator
    @StateObject private var fittingManager: ECKFittingManager
    @State private var presentedSheet: SheetItem?
    
    @State private var alertItem: AlertItem?
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
                                    alertItem = .renameFit(fitting)
                                    showChangeNameAlert = true
                                } label: {
                                    Label {
                                        Text("Change Name")
                                    } icon: {
                                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    }
                                }
                                
                                Button {
                                    alertItem = .deleteFit(fitting)
                                    showChangeNameAlert = true
                                } label: {
                                    Label {
                                        Text("Delete Fit")
                                    } icon: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    alertItem = .deleteFit(fitting)
                                    showChangeNameAlert = true
                                } label: {
                                    Label {
                                        Text("Delete Fit")
                                    } icon: {
                                        Image(systemName: "trash")
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
        .alert(alertItem?.title ?? "",
               isPresented: $showChangeNameAlert,
               presenting: alertItem,
               actions: { item in
            switch item {
            case .deleteFit(let fitting):
                deleteFitAlert(for: fitting)
            case .renameFit(let fitting):
                renameFitAlert(for: fitting)
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
    
    @ViewBuilder
    func renameFitAlert(for fitting: ECKCharacterFitting) -> some View {
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
    }
    
    @ViewBuilder
    func deleteFitAlert(for fitting: ECKCharacterFitting) -> some View {
        Button(role: .destructive) {
            fittingManager.deleteFit(fitting)
        } label: {
            Text("Delete")
        }
        
        Button(role: .cancel) {
            changeNameInput = fitting.name
        } label: {
            Text("Cancel")
        }
    }
}

#Preview {
    CoordinatorView(initialScreen: .fittingsList(.init(character: .dummy, isPreview: true)))
}
