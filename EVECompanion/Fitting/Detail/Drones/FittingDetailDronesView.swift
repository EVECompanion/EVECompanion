//
//  FittingDetailDronesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailDronesView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    let character: ECKCharacter
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            ForEach(fitting.drones) { drone in 
                HStack {
                    ECImage(id: drone.item.typeId, category: .types)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading) {
                        Text("\(drone.quantity)x " + drone.item.name)
                        Text(drone.state.title)
                    }
                }
            }
        }
    }
    
}

#Preview {
    FittingDetailDronesView(character: .dummy, fitting: .dummyAvatar)
}
