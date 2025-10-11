//
//  FittingImplantSearchView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 11.10.25.
//

import SwiftUI
import EVECompanionKit

struct FittingImplantSearchView: View {
    
    enum ImplantSelectionResult {
        case item(ECKItem)
        case remove(ECKCharacterFittingItem)
    }
    
    @Environment(\.dismiss) var dismiss
    private let implantSlot: Int
    private let completion: (ImplantSelectionResult) -> Void
    private let implantToReplace: ECKCharacterFittingItem?
    @State private var allImplants: [ECKItem]
    @State private var searchString: String = ""
    @State private var itemToDisplay: ECKItem?
    private var filteredImplants: [ECKItem] {
        if searchString.isEmpty {
            return allImplants
        } else {
            return allImplants.filter({ $0.name.contains(searchString) })
        }
    }
    
    init(implantSlot: Int,
         implantToReplace: ECKCharacterFittingItem?,
         _ completion: @escaping (ImplantSelectionResult) -> Void) {
        self.implantSlot = implantSlot
        self.implantToReplace = implantToReplace
        self.allImplants = ECKSDEManager.shared.getImplants(for: implantSlot, text: nil)
        self.completion = completion
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let implantToReplace {
                    Section {
                        Button {
                            completion(.remove(implantToReplace))
                            dismiss()
                        } label: {
                            Label {
                                Text("Remove \(implantToReplace.item.name)")
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(filteredImplants) { implant in
                        Button {
                            completion(.item(implant))
                            dismiss()
                        } label: {
                            HStack {
                                ECImage(id: implant.typeId, category: .types)
                                    .frame(width: 40, height: 40)
                                
                                Text(implant.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button {
                                    self.itemToDisplay = implant
                                } label: {
                                    Image(systemName: "info.circle")
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchString)
            .navigationTitle("Select Implant for Slot \(implantSlot)")
            .sheet(item: $itemToDisplay) { item in
                CoordinatorView(initialScreen: .item(item))
            }
        }
    }
    
}

#Preview {
    FittingImplantSearchView(implantSlot: 1,
                             implantToReplace: .init(flag: .Implant,
                                                     quantity: 1,
                                                     item: .init(typeId: 20499))) { _ in
        
    }
}
