//
//  PlanetaryColonyWarningsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.04.25.
//

import SwiftUI
import EVECompanionKit

struct PlanetaryColonyWarningsView: View {
    
    typealias Warning = ECKPlanetaryColonyDetails.Warning
    
    let warnings: Set<Warning>
    
    var body: some View {
        if warnings.contains(.storageRunningFull) {
            warningLabel(text: "A storage is almost full.", iconColor: .yellow)
        }
        
        if warnings.contains(.extractionExpiresSoon) {
            warningLabel(text: "An extraction program finishes soon.", iconColor: .yellow)
        }
        
        if warnings.contains(.extractionExpired) {
            warningLabel(text: "Extraction program finished.", iconColor: .red)
        }
    }
    
    @ViewBuilder
    private func warningLabel(text: String, iconColor: Color) -> some View {
        Label {
            Text(text)
                .bold()
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(iconColor)
        }
    }
    
}
