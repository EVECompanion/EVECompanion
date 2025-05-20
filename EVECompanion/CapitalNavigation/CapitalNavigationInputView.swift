//
//  CapitalNavigationInputView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 10.03.25.
//

import SwiftUI
import EVECompanionKit

struct CapitalNavigationInputView: View {
    
    @ObservedObject var manager: ECKCapitalNavigationManager
    @Binding var newSolarSystemTarget: CapitalNavigationView.NewSolarSystemTarget
    @Binding var isSolarSystemPickerPresented: Bool
    @Binding var isShipPickerPresented: Bool
    
    var body: some View {
        shipSection
        skillsSection
        destinationSection(title: "Destinations",
                           systems: $manager.selectedDestinationSystems,
                           target: .destination,
                           moveDisabled: false)
        destinationSection(title: "Systems To Avoid",
                           systems: $manager.selectedAvoidanceSystems,
                           target: .avoidance,
                           moveDisabled: true)
    }
    
    private var shipSection: some View {
        Section("Ship") {
            Button {
                isShipPickerPresented = true
            } label: {
                if let ship = manager.selectedShip {
                    HStack {
                        ECImage(id: ship.typeId, category: .types)
                            .frame(width: 40, height: 40)
                            .id(ship.typeId)
                        
                        Text(ship.name)
                    }
                } else {
                    Text("No ship selected")
                }
            }
        }
    }
    
    private var skillsSection: some View {
        Section {
            Picker("Jump Drive Calibration", selection: $manager.jdcSkillLevel) {
                ForEach(0...5, id: \.self) { level in
                    Text(ECFormatters.skillLevel(level: level,
                                                 showUntrainedString: true))
                }
            }
            
            Picker("Jump Fuel Conservation", selection: $manager.jfcSkillLevel) {
                ForEach(0...5, id: \.self) { level in
                    Text(ECFormatters.skillLevel(level: level,
                                                 showUntrainedString: true))
                }
            }
            
            if manager.selectedShip?.isJumpFreighter ?? false {
                Picker("Jump Freighter", selection: $manager.jumpFreighterSkillLevel) {
                    ForEach(0...5, id: \.self) { level in
                        Text(ECFormatters.skillLevel(level: level,
                                                     showUntrainedString: true))
                    }
                }
            }
        } header: {
            Text("Skills")
        } footer: {
            if let jumpRange = manager.jumpRange {
                Text("Jump Range: \(ECFormatters.jumpRange(jumpRange)) lightyears")
            }
        }
    }
    
    @ViewBuilder
    private func destinationSection(title: String,
                                    systems: Binding<[ECKCapitalJumpRoute.SystemEntry]>,
                                    target: CapitalNavigationView.NewSolarSystemTarget,
                                    moveDisabled: Bool) -> some View {
        Section {
            ForEach(systems) { entry in
                SolarSystemCell(system: entry.system.wrappedValue)
                    .moveDisabled(moveDisabled)
            }
            .onMove { IndexSet, index in
                systems.wrappedValue.move(fromOffsets: IndexSet, toOffset: index)
            }
            .onDelete { deleteOffsets in
                systems.wrappedValue.remove(atOffsets: deleteOffsets)
            }
            
            addSystemButton(target: target)
        } header: {
            HStack {
                Text(title)
                Spacer()
                if systems.isEmpty == false {
                    EditButton()
                }
            }
        }
    }
    
    @ViewBuilder
    private func addSystemButton(target: CapitalNavigationView.NewSolarSystemTarget) -> some View {
        Button {
            newSolarSystemTarget = target
            isSolarSystemPickerPresented = true
        } label: {
            Text(target.buttonTitle)
        }
    }
    
}

#Preview {
    Form {
        CapitalNavigationInputView(manager: .init(),
                                   newSolarSystemTarget: .constant(.destination),
                                   isSolarSystemPickerPresented: .constant(false),
                                   isShipPickerPresented: .constant(false))
    }
}
