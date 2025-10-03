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
        
        var id: String {
            switch self {
            case .rig:
                "rig"
            case .subsystem:
                "subsystem"
            case .module(let moduleSlotType):
                "module-\(moduleSlotType.rawValue)"
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
            }
        }
        
        var effectIdFilter: Int? {
            switch self {
            case .rig:
                return nil
            case .subsystem:
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
                             effectIdFilter: moduleType.effectIdFilter,
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
            ModuleSelectionView(moduleType: .module(.high),
                                targetShip: .init(typeId: 11567)) { _ in
                return
            }
        }
}
