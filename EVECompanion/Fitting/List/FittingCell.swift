//
//  FittingCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingCell: View {
    
    let fitting: ECKCharacterFitting
    
    var body: some View {
        HStack {
            ECImage(id: fitting.ship.typeId, category: .types)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(fitting.name)
                
                Text(fitting.ship.name)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
}

#Preview {
    List {
        FittingCell(fitting: .dummyAvatar)
    }
}
