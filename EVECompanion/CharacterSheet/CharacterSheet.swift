//
//  CharacterSheet.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 21.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct CharacterSheet: View {
    
    @ObservedObject var character: ECKCharacter
    let jumpFatigueTimer = Timer.publish(every: 1,
                                         on: .main,
                                         in: .common).autoconnect()
    
    var body: some View {
        List {
            characterCell
            
            Section {
                
                if let birthday = character.publicInfo?.birthday {
                    keyValueCell(key: "Date of Birth",
                                 value: ECFormatters.dateFormatter(date: birthday))
                }
                
                if let securityStatus = character.publicInfo?.securityStatus {
                    keyValueCell(key: "Security Status",
                                 value: ECFormatters.securityStatus(securityStatus))
                }
                
                if let jumpFatigueRemainingTime = character.jumpFatigue?.remainingTime {
                    imageValueCell(image: "Icons/JumpFatigue",
                                   key: "Jump Fatigue",
                                   value: ECFormatters.remainingTime(remainingTime: jumpFatigueRemainingTime))
                }
            }
            
            if let skills = character.skills {
                Section("Skills") {
                    keyValueCell(key: "Total SP",
                                 value: ECFormatters.skillPointsLong(skills.totalSP))
                    
                    if let unallocatedSP = skills.unallocatedSP {
                        keyValueCell(key: "Unallocated SP",
                                     value: ECFormatters.skillPointsLong(unallocatedSP))
                    }
                }
            }
            
            if let attributes = character.attributes {
                Section("Attributes") {
                    imageValueCell(image: "Attributes/charisma",
                                   key: "Charisma",
                                   value: attributes.charisma.description)
                    imageValueCell(image: "Attributes/intelligence",
                                   key: "Intelligence",
                                   value: attributes.intelligence.description)
                    imageValueCell(image: "Attributes/memory",
                                   key: "Memory",
                                   value: attributes.memory.description)
                    imageValueCell(image: "Attributes/perception",
                                   key: "Perception",
                                   value: attributes.perception.description)
                    imageValueCell(image: "Attributes/willpower",
                                   key: "Willpower",
                                   value: attributes.willpower.description)
                    
                    keyValueCell(key: "Bonus Remaps",
                                 value: attributes.bonusRemaps?.description ?? "0")
                    
                    if let nextRemapDate = attributes.accruedRemapCooldownDate {
                        if nextRemapDate < Date() {
                            keyValueCell(key: "Next Remap Available",
                                         value: "Now")
                        } else {
                            keyValueCell(key: "Next Remap Available",
                                         value: ECFormatters.dateFormatter(date: nextRemapDate))
                        }
                    } else {
                        keyValueCell(key: "Next Remap Available",
                                     value: "Now")
                    }
                }
            }
            
            if let implants = character.implants {
                Section("Implants") {
                    if implants.isEmpty {
                        Text("No Implants")
                    } else {
                        ForEach(implants) { implant in
                            NavigationLink(value: AppScreen.item(implant)) {
                                HStack {
                                    ECImage(id: implant.typeId,
                                            category: .types)
                                        .frame(width: 40,
                                               height: 40)
                                    
                                    Text(implant.name)
                                }
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await character.loadSheetData()
        }
        .navigationTitle(character.name)
        .onAppear(perform: {
            Task { @MainActor in
                await character.loadSheetData()
            }
        })
        .onReceive(jumpFatigueTimer, perform: { _ in
            character.objectWillChange.send()
        })
    }
    
    @ViewBuilder
    var characterCell: some View {
        HStack {
            ECImage(id: character.id,
                    category: .character)
                .frame(width: 80,
                       height: 80)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                if let corporation = character.corporation {
                    HStack {
                        if let corporationId = character.publicInfo?.corporationId {
                            ECImage(id: corporationId,
                                    category: .corporation)
                                .frame(width: 40,
                                       height: 40)
                        }
                        Text(corporation.name)
                    }
                }
                
                if let alliance = character.alliance {
                    HStack {
                        if let allianceId = character.publicInfo?.allianceId {
                            ECImage(id: allianceId,
                                    category: .alliance)
                                .frame(width: 40,
                                       height: 40)
                        }
                        Text(alliance.name)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func keyValueCell(key: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(key)
            Text(value)
                .foregroundStyle(Color.secondary)
        }
    }
    
    @ViewBuilder
    func imageValueCell(image: String,
                        key: String,
                        value: String) -> some View {
        HStack {
            Image(image)
                .resizable()
                .frame(width: 40, height: 40)
            keyValueCell(key: key,
                         value: value)
        }
    }
    
}

#Preview {
    NavigationStack {
        CharacterSheet(character: .dummy)
    }
}
