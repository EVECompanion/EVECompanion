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
    @State private var showsBottomSheet = false
    @State private var bottomSheetContentHeight: CGFloat = 300

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
        .toolbar {
            if character.skillqueue?.currentEntries.isEmpty == false {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsBottomSheet = true
                    } label: {
                        Image("Neocom/Augmentations")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                }
            }
        }
        .sheet(isPresented: $showsBottomSheet) {
            SkillPlanRemapPointCell(remap: character.skillqueue?.calculateOptimalRemap(),
                                    title: "Optimal Remap")
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .presentationDetents([.height(bottomSheetContentHeight)])
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { bottomSheetContentHeight = geo.size.height }
                    }
                }
        }
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
