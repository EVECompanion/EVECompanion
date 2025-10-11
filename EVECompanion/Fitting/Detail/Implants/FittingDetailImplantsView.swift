//
//  FittingDetailImplantsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.10.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailImplantsView: View {
    
    enum SheetItem: Identifiable {
        var id: String {
            switch self {
            case .implantSelection(let slot, let implantToReplace):
                if let implantToReplace {
                    return "\(slot)-\(implantToReplace.id)"
                } else {
                    return "\(slot)"
                }
                
            }
        }
        
        case implantSelection(slot: Int, implantToReplace: ECKCharacterFittingItem?)
    }
    
    @ObservedObject private var fitting: ECKCharacterFitting
    let fittingManager: ECKFittingManager
    @State private var sheetItem: SheetItem?
    
    init(fitting: ECKCharacterFitting, fittingManager: ECKFittingManager) {
        self.fitting = fitting
        self.fittingManager = fittingManager
    }
    
    var body: some View {
        List(1..<11) { implantSlot in
            let implant = implant(for: implantSlot)
            Button {
                sheetItem = .implantSelection(slot: implantSlot, implantToReplace: implant)
            } label: {
                label(for: implantSlot, implant: implant)
            }
        }
        .sheet(item: $sheetItem) { sheetItem in
            switch sheetItem {
            case .implantSelection(let slot, let implantToReplace):
                FittingImplantSearchView(implantSlot: slot,
                                         implantToReplace: implantToReplace) { result in
                    switch result {
                    case .item(let newImplant):
                        fitting.addImplant(newImplant: newImplant,
                                           implantToReplace: implantToReplace,
                                           manager: fittingManager)
                    case .remove(let implant):
                        fitting.removeImplant(implant,
                                              manager: fittingManager)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func label(for implantSlot: Int, implant: ECKCharacterFittingItem?) -> some View {
        if let implant = implant {
            HStack {
                ECImage(id: implant.item.typeId, category: .types)
                    .frame(width: 40, height: 40)
                
                Text(implant.item.name)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        } else {
            HStack {
                Image("Fitting/implant")
                    .resizable()
                    .frame(width: 40, height: 40)
                
                Text("Empty Implant Slot \(implantSlot)")
            }
        }
    }
    
    func implant(for slot: Int) -> ECKCharacterFittingItem? {
        return fitting.implants.first(where: {
            guard let implantSlotAttribute = $0.attributes[331] else {
                logger.warning("Item \($0.item.name) has no implant slot.")
                return false
            }
            
            return Int(implantSlotAttribute.value ?? implantSlotAttribute.baseValue) == slot
        })
    }
    
}

#Preview {
    FittingDetailImplantsView(fitting: .dummyAvatar,
                              fittingManager: .init(character: .dummy, isPreview: true))
        .onAppear {
            Task {
                await ECKCharacterFitting.dummyAvatar.calculateAttributes(skills: .empty)
            }
        }
}
