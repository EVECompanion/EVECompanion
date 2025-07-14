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
    
    init(target: ECKItem, _ completion: @escaping (ECKItem) -> Void) {
        self.target = target
        let chargeSize = ECKSDEManager.shared.getAttributeValue(attributeId: 128,
                                                                typeId: target.typeId)
        self.charges = ECKSDEManager.shared.possibleCharges(typeId: target.typeId,
                                                            chargeSize: chargeSize)
        self.completion = completion
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(charges) { charge in
                        Button {
                            completion(charge)
                            dismiss()
                        } label: {
                            HStack {
                                ECImage(id: charge.typeId, category: .types)
                                    .frame(width: 40, height: 40)
                                
                                Text(charge.name)
                            }
                        }
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
