//
//  FittingDamageProfileView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 15.07.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDamageProfileView: View {
    
    private let damageProfile: ECKCharacterFitting.DamageProfile
    private let compactMode: Bool
    
    init(damageProfile: ECKCharacterFitting.DamageProfile, compactMode: Bool = false) {
        self.damageProfile = damageProfile
        self.compactMode = compactMode
    }
    
    var body: some View {
        Grid(alignment: .center, horizontalSpacing: 20) {
            GridRow {
                Text("")
                if compactMode == false {
                    Image("Fitting/Resistances/em")
                    Image("Fitting/Resistances/thermal")
                    Image("Fitting/Resistances/kinetic")
                    Image("Fitting/Resistances/explosive")
                }
                Text(compactMode ? "" :"Total")
            }
            if compactMode == false {
                Divider()
            }
            if damageProfile.emDPS > 0
                || damageProfile.thermalDPS > 0
                || damageProfile.kineticDPS > 0
                || damageProfile.explosiveDPS > 0 {
                GridRow {
                    Text("DPS")
                        .bold()
                    
                    if compactMode == false {
                        Text(ECFormatters.attributeValue(damageProfile.emDPS, maximumFractionDigits: 1))
                            .tint(.blue)
                        Text(ECFormatters.attributeValue(damageProfile.thermalDPS, maximumFractionDigits: 1))
                            .tint(.red)
                        Text(ECFormatters.attributeValue(damageProfile.kineticDPS, maximumFractionDigits: 1))
                            .tint(.gray)
                        Text(ECFormatters.attributeValue(damageProfile.explosiveDPS, maximumFractionDigits: 1))
                            .tint(.orange)
                    }
                    Text(ECFormatters.attributeValue(damageProfile.dpsWithoutReload, maximumFractionDigits: 1))
                }
                Divider()
            }
            GridRow {
                Text("Volley")
                    .bold()
                if compactMode == false {
                    Text(ECFormatters.attributeValue(damageProfile.em, maximumFractionDigits: 1))
                        .tint(.blue)
                    Text(ECFormatters.attributeValue(damageProfile.thermal, maximumFractionDigits: 1))
                        .tint(.red)
                    Text(ECFormatters.attributeValue(damageProfile.kinetic, maximumFractionDigits: 1))
                        .tint(.gray)
                    Text(ECFormatters.attributeValue(damageProfile.explosive, maximumFractionDigits: 1))
                        .tint(.orange)
                }
                Text(ECFormatters.attributeValue(damageProfile.volleyDamage, maximumFractionDigits: 1))
            }
        }
    }
    
}

#Preview {
    FittingDamageProfileView(damageProfile: .dummy)
}

#Preview("Compact") {
    FittingDamageProfileView(damageProfile: .dummy, compactMode: true)
}
