//
//  LoyaltyPointsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import SwiftUI
import EVECompanionKit

struct LoyaltyPointsView: View {
    
    @ObservedObject var character: ECKCharacter
    
    var body: some View {
        List(character.loyaltyPoints ?? []) { entry in
            LoyaltyPointCell(entry: entry)
        }
        .onAppear(perform: {
            Task {
                await character.loadLoyaltyPoints()
            }
        })
        .refreshable {
            await character.loadLoyaltyPoints()
        }
    }
    
}

#Preview {
    LoyaltyPointsView(character: .dummy)
}
