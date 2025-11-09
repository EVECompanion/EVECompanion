//
//  MultiCharacterSkillQueueEntryView.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import SwiftUI
import EVECompanionKit
import Kingfisher

struct MultiCharacterSkillQueueEntryView: View {
    var entry: MultiCharacterSkillQueueWidgetTimelineProvider.Entry
    
    init(entry: MultiCharacterSkillQueueWidgetTimelineProvider.Entry) {
        self.entry = entry
    }
    
    var body: some View {
        VStack {
            ForEach(entry.entries.enumerated(), id: \.offset) { offset, entry in
                HStack {
                    KFImage(URL(string: "https://images.evetech.net/characters/\(entry.character.id)/portrait?size=512")!)
                        .resizable()
                        .frame(width: 60,
                               height: 60)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(entry.character.name)
                            .bold()
                            .font(.title2)
                        
                        skillRow(for: entry)
                    }
                    Spacer()
                }
                
                if offset < self.entry.entries.count - 1 {
                    Divider()
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func skillRow(for entry: SkillQueueWidgetTimelineEntry) -> some View {
        if let currentSkill = entry.skillQueue.first {
            if let finishDate = currentSkill.finishDate {
                VStack(alignment: .leading) {
                    Text(currentSkill.skillName)
                    Text(finishDate, style: .timer)
                }
                .bold()
            } else {
                VStack(alignment: .leading) {
                    Text(currentSkill.skillName)
                    Text("Paused")
                }
                .foregroundStyle(.secondary)
            }
        } else if entry.character.id == WidgetCharacter.dummy1.id {
            Text("You can change the selected character by editing this widget.")
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
        } else {
            Text("No skill in training")
                .foregroundStyle(.secondary)
        }
    }
}
