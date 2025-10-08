//
//  ModuleSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.09.25.
//

import SwiftUI
import EVECompanionKit

struct ModuleSelectionView: View {
    
    enum ModuleType: Identifiable {
        case rig
        case subsystem
        case module(ECKCharacterFitting.ModuleSlotType)
        case drone
        
        var id: String {
            switch self {
            case .rig:
                "rig"
            case .subsystem:
                "subsystem"
            case .module(let moduleSlotType):
                "module-\(moduleSlotType.rawValue)"
            case .drone:
                "drone"
            }
        }
        
        var marketGroupIdFilter: Int {
            switch self {
            case .rig:
                return 1111
            case .subsystem:
                return 1112
            case .module:
                return 9
            case .drone:
                return 157
            }
        }
        
        var title: String {
            switch self {
            case .rig:
                return "Rig Selection"
            case .subsystem:
                return "Subsystem Selection"
            case .module(let slotType):
                switch slotType {
                case .rig:
                    return "Rig Selection"
                case .subsystem:
                    return "Subsystem Selection"
                case .high:
                    return "High Slot Module"
                case .mid:
                    return "Mid Slot Module"
                case .low:
                    return "Low Slot Module"
                }
            case .drone:
                return "Drone Selection"
            }
        }
        
        var effectIdFilter: Int? {
            switch self {
            case .rig:
                return nil
            case .subsystem:
                return nil
            case .drone:
                return nil
            case .module(let moduleSlotType):
                switch moduleSlotType {
                case .rig:
                    return nil
                case .subsystem:
                    return nil
                case .high:
                    return 12
                case .mid:
                    return 13
                case .low:
                    return 11
                }
            }
        }
    }
    
    enum ModuleSelectionResult {
        case item(ECKItem)
        case remove
    }
    
    private let searchHistoryDefaultsKey: String
    private let moduleType: ModuleType
    private let itemToReplace: ECKItem?
    private let targetShip: ECKItem
    private let selectionHandler: (ModuleSelectionResult) -> Void
    @Environment(\.dismiss) var dismiss
    @State var searchHistory: [ECKItem]
    
    init(moduleType: ModuleType,
         targetShip: ECKItem,
         itemToReplace: ECKItem?,
         selectionHandler: @escaping (ModuleSelectionResult) -> Void) {
        self.moduleType = moduleType
        self.targetShip = targetShip
        self.itemToReplace = itemToReplace
        self.selectionHandler = selectionHandler
        self.searchHistoryDefaultsKey = "Fitting.ModuleSelection.\(moduleType.id)"
        
        // Load search history
        let itemIds = UserDefaults.standard.array(forKey: searchHistoryDefaultsKey) as? [Int] ?? []
        self.searchHistory = itemIds.map({ .init(typeId: $0) })
    }
    
    var body: some View {
        NavigationStack {
            MarketGroupsView(groupIdFilter: nil,
                             marketGroupIdFilter: moduleType.marketGroupIdFilter,
                             effectIdFilter: moduleType.effectIdFilter,
                             customTitle: moduleType.title) {
                Group {
                    if let itemToReplace {
                        Section {
                            Button {
                                removeModule()
                            } label: {
                                Label {
                                    Text("Remove \(itemToReplace.name)")
                                } icon: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    
                    if searchHistory.isEmpty == false {
                        Section("History") {
                            ForEach(searchHistory) { item in
                                Button {
                                    didSelect(item)
                                } label: {
                                    HStack {
                                        ECImage(id: item.typeId,
                                                category: .types)
                                        .frame(width: 40,
                                               height: 40)
                                        
                                        Text(item.name)
                                    }
                                }
                            }
                        }
                    }
                }
            } customSectionHeader: {
                if let itemToReplace {
                    VStack(alignment: .leading) {
                        Text("Replacing:")
                        
                        HStack {
                            ECImage(id: itemToReplace.typeId, category: .types)
                                .frame(width: 40, height: 40)
                            
                            Text(itemToReplace.name)
                        }
                    }
                } else {
                    nil
                }
            } selectionHandler: { item in
                didSelect(item)
            }
        }
    }
    
    private func didSelect(_ item: ECKItem) {
        addToSearchHistory(item: item)
        selectionHandler(.item(item))
        dismiss()
    }
    
    private func removeModule() {
        selectionHandler(.remove)
        dismiss()
    }
    
    private func addToSearchHistory(item: ECKItem) {
        var searchHistory = self.searchHistory
        searchHistory.removeAll { $0.id == item.id }
        searchHistory.insert(item, at: 0)
        searchHistory = Array(searchHistory.prefix(5))
        UserDefaults.standard.set(searchHistory.map(\.self.id), forKey: searchHistoryDefaultsKey)
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ModuleSelectionView(moduleType: .module(.high),
                                targetShip: .init(typeId: 11567),
                                itemToReplace: .init(typeId: 40357)) { _ in
                return
            }
        }
}
