//
//  EVECompanionWidgets.swift
//  EVECompanionWidgets
//
//  Created by Jonas Schlabertz on 21.10.25.
//

import WidgetKit
import SwiftUI
import EVECompanionKit
import Kingfisher

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SkillQueueWidgetTimelineEntry {
        SkillQueueWidgetTimelineEntry.dummy1
    }

    func snapshot(for configuration: SkillQueueWidgetConfiguration, in context: Context) async -> SkillQueueWidgetTimelineEntry {
        SkillQueueWidgetTimelineEntry.dummy2
    }
    
    func timeline(for configuration: SkillQueueWidgetConfiguration, in context: Context) async -> Timeline<SkillQueueWidgetTimelineEntry> {
        let entries: [SkillQueueWidgetTimelineEntry] = [.dummy1, .dummy2]
        
        var imageResources: [any Resource] = []
        
        if let url = await ECKImageManager().loadURL(id: configuration.character.id,
                                                     category: .character,
                                                     isBPC: false) {
            imageResources.append(KF.ImageResource(downloadURL: url.appending(queryItems: [.init(name: "size", value: "512")])))
        }
        
        await withCheckedContinuation { continuation in
            ImagePrefetcher(resources: imageResources, options: [
                .forceRefresh,
                .processor(ResizingImageProcessor(referenceSize: .init(width: 800, height: 800)))
            ]) { _, _, _ in
                continuation.resume()
            }.start()
        }
        
        return Timeline(entries: entries, policy: .never)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct WidgetCharacter {
    let name: String
    let id: Int
    
    init(character: ECKCharacter) {
        self.name = character.name
        self.id = character.id
    }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    static var dummy: WidgetCharacter {
        return .init(id: 2123087197, name: "EVECompanion")
    }
}

struct SkillQueueWidgetTimelineEntry: TimelineEntry {
    var date: Date {
        skillQueue.first?.startDate ?? Date()
    }
    
    let character: WidgetCharacter
    let skillQueue: [SkillQueueEntry]
    
    init(character: WidgetCharacter, skillQueue: [SkillQueueEntry]) {
        self.character = character
        self.skillQueue = skillQueue
    }
    
    static var dummy1: SkillQueueWidgetTimelineEntry {
        return .init(character: .dummy, skillQueue: [.dummy1, .dummy2])
    }
    
    static var dummy2: SkillQueueWidgetTimelineEntry {
        return .init(character: .dummy, skillQueue: [.dummy2])
    }
}

struct SkillQueueEntry: Identifiable {
    
    var id: String {
        return skillName
    }
    
    let skillName: String
    let startDate: Date
    let finishDate: Date
    
    static var dummy1: SkillQueueEntry {
        return .init(skillName: "Amarr Titan IV",
                     startDate: Date() - 3600,
                     finishDate: Date() + 120)
    }
    
    static var dummy2: SkillQueueEntry {
        return .init(skillName: "Amarr Titan V",
                     startDate: Date() + 121,
                     finishDate: Date() + 3600 + 121)
    }
}

struct EVECompanionWidgetsEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(alignment: .leading) {
            characterCell
            
            if let activeSkill = entry.skillQueue.first {
                skillCell(for: activeSkill, isActive: true)
            }
            
            if widgetFamily != .systemSmall {
                ForEach(entry.skillQueue.dropFirst()) { skill in
                    skillCell(for: skill, isActive: false)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func skillCell(for skill: SkillQueueEntry, isActive: Bool) -> some View {
        HStack {
            Text(skill.skillName)
            if isActive {
                Text(skill.finishDate, style: .timer)
            } else {
                Text(ECFormatters.timeInterval(timeInterval: skill.finishDate.timeIntervalSince(skill.startDate)))
            }
        }
        
        Text("Completes \(ECFormatters.dateFormatter(date: skill.finishDate))")
            .foregroundStyle(Color.secondary)
    }
    
    @ViewBuilder
    var characterCell: some View {
        HStack {
            KFImage(URL(string: "https://images.evetech.net/characters/\(entry.character.id)/portrait?size=512")!)
                .resizable()
                .frame(width: 60,
                       height: 60)
                .clipShape(Circle())
            
            Text(entry.character.name)
        }
    }
}

struct EVECompanionWidgets: Widget {
    let kind: String = "EVECompanionWidgets"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: SkillQueueWidgetConfiguration.self,
                               provider: Provider()) { entry in
            EVECompanionWidgetsEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

extension SkillQueueWidgetConfiguration {
    fileprivate static var smiley: SkillQueueWidgetConfiguration {
        let intent = SkillQueueWidgetConfiguration()
        
        return intent
    }
    
    fileprivate static var starEyes: SkillQueueWidgetConfiguration {
        let intent = SkillQueueWidgetConfiguration()
        
        return intent
    }
}

#Preview(as: .systemSmall) {
    EVECompanionWidgets()
} timeline: {
    SkillQueueWidgetTimelineEntry.dummy1
    SkillQueueWidgetTimelineEntry.dummy2
}
