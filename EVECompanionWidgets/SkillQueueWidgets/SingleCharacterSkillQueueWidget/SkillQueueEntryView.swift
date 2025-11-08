//
//  SkillQueueEntryView.swift
//  EVECompanionWidgets
//
//  Created by Jonas Schlabertz on 21.10.25.
//

import WidgetKit
import SwiftUI
import EVECompanionKit
import Kingfisher

struct SkillQueueEntryView: View {
    var entry: SkillQueueWidgetTimelineProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var numberOfSkills: Int {
        switch widgetFamily {
            
        case .systemSmall:
            return 0
        case .systemMedium:
            return 0
        case .systemLarge:
            return 2
        case .systemExtraLarge:
            return 2
        case .accessoryCircular:
            return 0
        case .accessoryRectangular:
            return 0
        case .accessoryInline:
            return 0
        @unknown default:
            return 0
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            characterCell
            
            Spacer()
                .frame(height: 10)
            
            if let activeSkill = entry.skillQueue.first {
                skillCell(for: activeSkill, isActive: true)
                
                ForEach(entry.skillQueue.dropFirst().prefix(numberOfSkills)) { skill in
                    Divider()
                    skillCell(for: skill, isActive: false)
                }
            } else {
                Text("No skill in training")
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func skillCell(for skill: SkillQueueEntry, isActive: Bool) -> some View {
        Text(skill.skillName)
            
        if let finishDate = skill.finishDate,
           let startDate = skill.startDate {
            if isActive {
                Text(finishDate, style: .timer)
                    .bold()
            } else {
                Text(ECFormatters.timeInterval(timeInterval: finishDate.timeIntervalSince(startDate)))
            }
        } else {
            Text("Paused")
                .foregroundStyle(.secondary)
        }
        
        if let finishDate = skill.finishDate {
            Text("Completes \(ECFormatters.dateFormatter(date: finishDate))")
                .foregroundStyle(Color.secondary)
        }
    }
    
    @ViewBuilder
    var characterCell: some View {
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
             
                if entry.character.id == WidgetCharacter.dummy1.id {
                    Text("You can change the selected character by editing this widget.")
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}
