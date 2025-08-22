//
//  SkillQueueView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 14.05.24.
//

import SwiftUI
import EVECompanionKit

struct SkillQueueView: View {
    
    @ObservedObject var character: ECKCharacter
    
    var body: some View {
        List(character.skillqueue?.currentEntries ?? []) { entry in
            NavigationLink(value: AppScreen.itemByTypeId(entry.skill.skillId)) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(entry.skill.name) \(ECFormatters.skillLevel(level: entry.finishLevel))")
                        
                        Spacer()
                        
                        Group {
                            if let remainingTime = entry.remainingTime,
                               entry == character.skillqueue?.first {
                                let remainingTimeString = "\(ECFormatters.remainingTime(remainingTime: remainingTime))"
                                
                                Text(remainingTimeString)
                            } else if let totalTime = entry.totalTime {
                                let timeString = "\(ECFormatters.remainingTime(remainingTime: totalTime))"
                                
                                Text(timeString)
                            }
                        }
                        .foregroundStyle(Color.secondary)
                    }
                    
                    if let finishDate = entry.finishDate {
                        Spacer()
                            .frame(height: 10)
                        
                        Text("Completes \(ECFormatters.dateFormatter(date: finishDate))")
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .refreshable {
            await character.reloadSkillQueue()
        }
        .navigationTitle("Skillqueue")
        .overlay {
            if (character.skillqueue?.currentEntries ?? []).isEmpty && character.initialDataLoadingState == .ready {
                ContentEmptyView(image: Image("Neocom/Skillqueue"),
                                 title: "No Skills in Skillqueue",
                                 subtitle: "Skills in your skillqueue will appear here.")
            }
        }
        .animation(.spring,
                   value: character.skillqueue?.currentEntries ?? [])
    }
    
}

#Preview {
    NavigationView {
        SkillQueueView(character: .dummy)
    }
}
