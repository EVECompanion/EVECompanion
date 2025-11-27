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
    @State private var showEHP: Bool = true
    
    init(resistances: ECKCharacterFitting.Resistances) {
        self.resistances = resistances
    }
    
    var body: some View {
        Grid {
            GridRow {
                Text("")
                
                Group {
                    Image("Fitting/shield")
                        .resizable()
                    Image("Fitting/armor")
                        .resizable()
                    Image("Fitting/structure")
                        .resizable()
                }
                .frame(width: 30, height: 30)
            }
            
            GridRow {
                Image("Fitting/Resistances/em")
                
                bar(value: resistances.shield.em, tint: .blue)
                bar(value: resistances.armor.em, tint: .blue)
                bar(value: resistances.structure.em, tint: .blue)
            }
            
            GridRow {
                Image("Fitting/Resistances/thermal")
                bar(value: resistances.shield.thermal, tint: .red)
                bar(value: resistances.armor.thermal, tint: .red)
                bar(value: resistances.structure.thermal, tint: .red)
            }
            
            GridRow {
                Image("Fitting/Resistances/kinetic")
                bar(value: resistances.shield.kinetic, tint: .gray)
                bar(value: resistances.armor.kinetic, tint: .gray)
                bar(value: resistances.structure.kinetic, tint: .gray)
            }
            
            GridRow {
                Image("Fitting/Resistances/explosive")
                bar(value: resistances.shield.explosive, tint: .orange)
                bar(value: resistances.armor.explosive, tint: .orange)
                bar(value: resistances.structure.explosive, tint: .orange)
            }
            
            GridRow {
                Button {
                    showEHP.toggle()
                } label: {
                    Text(showEHP ? "EHP" : "HP")
                }

                let unit: EVEUnit = showEHP ? .effectiveHitpoints : .hitpoints
                Text(unit.formatted(showEHP ? resistances.shield.ehp : resistances.shield.hp))
                    .font(.footnote)
                Text(unit.formatted(showEHP ? resistances.armor.ehp : resistances.armor.hp))
                    .font(.footnote)
                Text(unit.formatted(showEHP ? resistances.structure.ehp : resistances.structure.hp))
                    .font(.footnote)
            }
            .animation(.spring, value: showEHP)
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
