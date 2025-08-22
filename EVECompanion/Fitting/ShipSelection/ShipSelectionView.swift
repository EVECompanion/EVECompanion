//
//  ShipSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 16.07.25.
//

import SwiftUI
import EVECompanionKit

struct ShipSelectionView: View {

    private let completion: (ECKItem) -> Void
    @StateObject private var manager: ECKMarketGroupManager = .init(groupIdFilter: nil, marketGroupIdFilter: 4)
    @Environment(\.dismiss) var dismiss
    
    init(completion: @escaping (ECKItem) -> Void) {
        self.completion = completion
    }
    
    var body: some View {
        NavigationStack {
            List {
                OutlineGroup(manager.marketGroups, children: \.children) { type in
                    switch type {
                    case .item(let item):
                        Button {
                            dismiss()
                            completion(item)
                        } label: {
                            HStack {
                                ECImage(id: item.typeId,
                                        category: .types)
                                .frame(width: 40,
                                       height: 40)
                                
                                Text(item.name)
                            }
                        }
                        
                    case .marketGroup(let marketGroup):
                        Text(marketGroup.name)
                    }
                }
            }
            .navigationTitle("Select a Ship")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ShipSelectionView { _ in
                return
            }
        }
}
