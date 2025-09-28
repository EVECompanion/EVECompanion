//
//  ModuleSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.09.25.
//

import SwiftUI
import EVECompanionKit

struct ModuleSelectionView: View {
    
    enum ModuleType: String, Identifiable {
        case rig
        case subsystem
        case module
        
        var id: String {
            return self.rawValue
        }
        
        var marketGroupIdFilter: Int {
            switch self {
            case .rig:
                return 1111
            case .subsystem:
                return 1112
            case .module:
                return 9
            }
        }
        
        var title: String {
            switch self {
            case .rig:
                return "Rig Selection"
            case .subsystem:
                return "Subsystem Selection"
            case .module:
                return "Module Selection"
            }
        }
    }
    
    private let moduleType: ModuleType
    private let targetShip: ECKItem
    private let selectionHandler: (ECKItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    init(moduleType: ModuleType, targetShip: ECKItem, selectionHandler: @escaping (ECKItem) -> Void) {
        self.moduleType = moduleType
        self.targetShip = targetShip
        self.selectionHandler = selectionHandler
    }
    
    var body: some View {
        NavigationStack {
            MarketGroupsView(groupIdFilter: nil,
                             marketGroupIdFilter: moduleType.marketGroupIdFilter,
                             customTitle: moduleType.title) { item in
                selectionHandler(item)
                dismiss()
            }
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ModuleSelectionView(moduleType: .module, targetShip: .init(typeId: 11567)) { _ in
                return
            }
        }
}
