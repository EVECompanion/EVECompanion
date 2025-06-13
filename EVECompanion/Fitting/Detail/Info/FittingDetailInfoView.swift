//
//  FittingDetailInfoView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailInfoView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    let character: ECKCharacter
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            ForEach(fitting.fittingAttributes, id: \.attribute.id) { attribute in
                ItemAttributeCell(attribute: attribute.attribute,
                                  fittingAttribute: attribute.fittingAttribute)
            }
        }
        .task {
            fitting.calculateAttributes(skills: character.skills ?? .empty)
        }
    }
    
}

#Preview {
    FittingDetailInfoView(character: .dummy, fitting: .dummyAvatar)
}
