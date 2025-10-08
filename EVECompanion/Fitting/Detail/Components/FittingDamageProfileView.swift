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
                
                Text("DPS")
                
                Text ("Volley")
            }
            
            if compactMode == false {
                Divider()
                
                GridRow {
                    Image("Fitting/Resistances/em")
                    
                    Text(ECFormatters.shortenedValue(damageProfile.emDPS, maximumFractionDigits: 1))
                        .tint(.blue)
                    
                    Text(ECFormatters.shortenedValue(damageProfile.em, maximumFractionDigits: 1))
                        .tint(.blue)
                }
                
                Divider()
                
                GridRow {
                    Image("Fitting/Resistances/thermal")
                    
                    Text(ECFormatters.shortenedValue(damageProfile.thermalDPS, maximumFractionDigits: 1))
                        .tint(.red)
                    
                    Text(ECFormatters.shortenedValue(damageProfile.thermal, maximumFractionDigits: 1))
                        .tint(.red)
                }
                
                Divider()
                
                GridRow {
                    Image("Fitting/Resistances/kinetic")
                    
                    Text(ECFormatters.shortenedValue(damageProfile.kineticDPS, maximumFractionDigits: 1))
                        .tint(.gray)
                    
                    Text(ECFormatters.shortenedValue(damageProfile.kinetic, maximumFractionDigits: 1))
                        .tint(.gray)
                }
                
                Divider()
                
                GridRow {
                    Image("Fitting/Resistances/explosive")
                    
                    Text(ECFormatters.shortenedValue(damageProfile.explosiveDPS, maximumFractionDigits: 1))
                        .tint(.orange)
                    
                    Text(ECFormatters.shortenedValue(damageProfile.explosive, maximumFractionDigits: 1))
                        .tint(.orange)
                }
            }
            
            Divider()
            
            GridRow {
                Text("Total")
                Text(ECFormatters.shortenedValue(damageProfile.dpsWithoutReload, maximumFractionDigits: 1))
                Text(ECFormatters.shortenedValue(damageProfile.volleyDamage, maximumFractionDigits: 1))
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
