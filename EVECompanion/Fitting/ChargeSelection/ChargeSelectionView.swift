//
//  ChargeSelectionView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 09.07.25.
//

import SwiftUI
import EVECompanionKit

struct ChargeSelectionView: View {
    
    private let target: ECKItem
    private let charges: [ECKItem]
    private let completion: (ECKItem) -> Void
    @Environment(\.dismiss) private var dismiss
    private let searchHistoryDefaultsKey: String
    @State private var searchHistory: [ECKItem]
    
    init(target: ECKItem, _ completion: @escaping (ECKItem) -> Void) {
        self.target = target
        let chargeSize = ECKSDEManager.shared.getAttributeValue(attributeId: 128,
                                                                typeId: target.typeId)
        self.charges = ECKSDEManager.shared.possibleCharges(typeId: target.typeId,
                                                            chargeSize: chargeSize)
        self.completion = completion
        
        self.searchHistoryDefaultsKey = "Fitting.ModuleSelection.\(target.id)"
        
        // Load search history
        let itemIds = UserDefaults.standard.array(forKey: searchHistoryDefaultsKey) as? [Int] ?? []
        self.searchHistory = itemIds.map({ .init(typeId: $0) })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchHistory.isEmpty == false {
                    Section("History") {
                        ForEach(searchHistory) { charge in
                            chargeCellButton(charge)
                        }
                    }
                }
                
                Section {
                    ForEach(charges) { charge in
                        chargeCellButton(charge)
                    }
                } header: {
                    HStack {
                        ECImage(id: target.typeId, category: .types)
                            .frame(width: 40, height: 40)
                        
                        Text(target.name)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Possible Charges")
        }
    }
    
    private func chargeCellButton(_ charge: ECKItem) -> some View {
        Button {
            addToSearchHistory(item: charge)
            completion(charge)
            dismiss()
        } label: {
            chargeCell(charge)
        }
    }
    
    private func chargeCell(_ charge: ECKItem) -> some View {
        HStack {
            ECImage(id: charge.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            Text(charge.name)
        }
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
            ChargeSelectionView(target: .init(typeId: 2929)) { _ in
                return
            }
        }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ChargeSelectionView(target: .init(typeId: 33440)) { _ in
                return
            }
        }
}
