//
//  FittingResistancesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingResistancesView: View {
    
    private let resistances: ECKCharacterFitting.Resistances
    
    init(resistances: ECKCharacterFitting.Resistances) {
        self.resistances = resistances
    }
    
    var body: some View {
        Grid {
            GridRow {
                Text("")
                Image("Fitting/Resistances/em")
                Image("Fitting/Resistances/thermal")
                Image("Fitting/Resistances/kinetic")
                Image("Fitting/Resistances/explosive")
                Text("HP")
            }
            row(icon: "Fitting/shield", stats: resistances.shield)
            row(icon: "Fitting/armor", stats: resistances.armor)
            row(icon: "Fitting/structure", stats: resistances.structure)
        }
    }
    
    @ViewBuilder
    private func row(icon: String, stats: ECKCharacterFitting.ResistanceStats) -> some View {
        GridRow {
            Image(icon)
                .resizable()
                .frame(width: 30, height: 30)
            
            bar(value: stats.em, tint: .blue)
            bar(value: stats.thermal, tint: .red)
            bar(value: stats.kinetic, tint: .gray)
            bar(value: stats.explosive, tint: .orange)
            
            Text(EVEUnit.hitpoints.formatted(stats.hp))
                .font(.footnote)
        }
    }
    
    @ViewBuilder
    private func bar(value: Float, tint: Color) -> some View {
        ProgressView(value: 1 - value) {
            Text(EVEUnit.inverseAbsolutePercent.formatted(value))
                .font(.footnote)
        }
        .progressViewStyle(.linear)
        .animation(.spring, value: value)
        .tint(tint)
    }
    
}

#Preview {
    FittingResistancesView(resistances: ECKCharacterFitting.Resistances(structure: .init(hp: 390000, em: 0.6, explosive: 0.2, kinetic: 0.5, thermal: 0.3),
                                                                        armor: .init(hp: 11630000, em: 0.6, explosive: 0.2, kinetic: 0.5, thermal: 0.3),
                                                                        shield: .init(hp: 260000, em: 0.6, explosive: 0.2, kinetic: 0.5, thermal: 0.3)))
}
