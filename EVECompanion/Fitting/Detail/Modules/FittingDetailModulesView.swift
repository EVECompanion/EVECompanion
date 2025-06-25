//
//  FittingDetailModulesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailModulesView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    let character: ECKCharacter
    
    init(character: ECKCharacter, fitting: ECKCharacterFitting) {
        self.character = character
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            section(numberOfSlots: fitting.subsystemSlots, title: "Subsystems", icon: "Fitting/highslot") // TODO: Icon
            section(numberOfSlots: fitting.highSlots, title: "High Slots", icon: "Fitting/highslot")
            section(numberOfSlots: fitting.midSlots, title: "Mid Slots", icon: "Fitting/midslot")
            section(numberOfSlots: fitting.lowSlots, title: "Low Slots", icon: "Fitting/lowslot")
            section(numberOfSlots: fitting.rigSlots, title: "Rigs", icon: "Fitting/rigslot")
        }
    }
    
    @ViewBuilder
    private func section(numberOfSlots: Int, title: String, icon: String) -> some View {
        if numberOfSlots > 0 {
            Section {
                
            } header: {
                sectionHeader(text: title, icon: icon)
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(text: String, icon: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(icon)
                .resizable()
                .frame(width: 40, height: 40)
        }
    }
    
}

#Preview {
    FittingDetailModulesView(character: .dummy, fitting: .dummyAvatar)
}
