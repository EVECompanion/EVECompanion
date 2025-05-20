//
//  LoyaltyPointCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct LoyaltyPointCell: View {
    
    @ObservedObject var entry: ECKLoyaltyPointsEntry
    
    var body: some View {
        HStack {
            if let corporation = entry.corporation {
                ECImage(id: entry.corporationId,
                        category: .corporation)
                    .frame(width: 40, height: 40)
                Text(corporation.name)
            } else {
                ProgressView()
            }
            
            Spacer()
            Text(entry.loyaltyPoints.description)
        }
    }
    
}

#Preview {
    List {
        LoyaltyPointCell(entry: .dummy1)
        LoyaltyPointCell(entry: .dummy2)
    }
}
