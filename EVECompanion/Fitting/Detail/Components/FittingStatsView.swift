//
//  FittingStatsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.06.25.
//

import SwiftUI
import EVECompanionKit

struct FittingStatsView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    
    init(fitting: ECKCharacterFitting) {
        self.fitting = fitting
    }
    
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                entry(title: "Power",
                      icon: "Fitting/powergrid",
                      value: fitting.powerLoad ?? 0,
                      maxValue: fitting.powerOutput ?? 0,
                      unit: "MW",
                      tint: .red)
                
                entry(title: "CPU",
                      icon: "Fitting/cpu",
                      value: fitting.cpuLoad ?? 0,
                      maxValue: fitting.maxCPU ?? 0,
                      unit: "tf",
                      tint: .gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func entry(title: String, icon: String, value: Float, maxValue: Float, unit: String, tint: Color) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 30, height: 30)
            
            ProgressView(value: value, total: maxValue) {
                HStack {
                    Text(title)
                    
                    Spacer()
                    
                    Text("\(ECFormatters.shortenedValue(value, maximumFractionDigits: 1))/\(ECFormatters.shortenedValue(maxValue, maximumFractionDigits: 1))\(unit)")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
            }
                .progressViewStyle(.linear)
                .tint(tint)
        }
        
    }
    
}

#Preview {
    FittingDetailView(character: .dummy, fitting: .dummyAvatar)
}
