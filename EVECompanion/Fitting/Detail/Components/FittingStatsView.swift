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

            if fitting.canUseDrones {
                GridRow {
                    entry(title: "Drone Capacity",
                          icon: "Fitting/drones",
                          value: fitting.usedDroneCapacity ?? 0,
                          maxValue: fitting.maxDroneCapacity ?? 0,
                          unit: "m³",
                          tint: .yellow)
                    
                    entry(title: "Drone Bandwidth",
                          icon: "Fitting/drones",
                          value: fitting.usedDroneBandwidth ?? 0,
                          maxValue: fitting.maxDroneBandwidth ?? 0,
                          unit: "mbit/s",
                          tint: .blue)
                }
            }

            if fitting.canUseFighters {
                GridRow {
                    entry(title: "Fighter Hangar",
                          icon: "Fitting/drones",
                          value: fitting.usedFighterHangarCapacity ?? 0,
                          maxValue: fitting.maxFighterHangarCapacity ?? 0,
                          unit: "m³",
                          tint: .yellow)

                    entry(title: "Fighter Tubes",
                          icon: "Fitting/drones",
                          value: Float(fitting.usedFighterTubes),
                          maxValue: Float(fitting.fighterLaunchTubes),
                          unit: "",
                          tint: .blue)
                }
            }
            
            if let maxRigCalibration = fitting.maxRigCalibration, maxRigCalibration > 0 {
                GridRow {
                    entry(title: "Rig Calibration",
                          icon: "Fitting/rigslot",
                          value: fitting.usedRigCalibration,
                          maxValue: maxRigCalibration,
                          unit: "",
                          tint: .orange)
                }
                .gridCellColumns(2)
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
                    
                    let formattedValue = "\(ECFormatters.shortenedValue(value, maximumFractionDigits: 1))/\(ECFormatters.shortenedValue(maxValue, maximumFractionDigits: 1))"
                    Text(unit.isEmpty ? formattedValue : "\(formattedValue) \(unit)")
                        .foregroundStyle(.secondary)
                }
                .background {
                    if value > maxValue {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red)
                    }
                }
                .font(.footnote)
            }
            .progressViewStyle(.linear)
            .animation(.spring, value: value)
            .tint(tint)
        }
        
    }
    
}

#Preview("Avatar") {
    FittingDetailView(manager: .init(character: .dummy, isPreview: true), fitting: .dummyAvatar)
}
#Preview("VNI") {
    FittingDetailView(manager: .init(character: .dummy, isPreview: true), fitting: .dummyVNI)
}
