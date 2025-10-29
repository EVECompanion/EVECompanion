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
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SkillQueueWidgetTimelineEntry {
        SkillQueueWidgetTimelineEntry.dummy1
    }

    func snapshot(for configuration: SkillQueueWidgetConfiguration, in context: Context) async -> SkillQueueWidgetTimelineEntry {
        SkillQueueWidgetTimelineEntry.dummy2
    }
    
    func timeline(for configuration: SkillQueueWidgetConfiguration, in context: Context) async -> Timeline<SkillQueueWidgetTimelineEntry> {
        var entries: [SkillQueueWidgetTimelineEntry] = []
        
        let skillQueue = await ECKWidgetDataStorage.shared.loadSkillQueue(for: configuration.character.id)
        
        let skillQueueEntries = skillQueue?.skillQueue ?? []
        for skillQueueEntry in skillQueueEntries.enumerated() {
            let remainingEntries = Array(skillQueueEntries.dropFirst(skillQueueEntry.offset))
            let timelineStartDate: Date
            if let startDate = skillQueueEntry.element.startDate {
                timelineStartDate = startDate
            } else if skillQueueEntry.offset == 0 {
                timelineStartDate = Date()
            } else {
                continue
            }
            
            entries.append(.init(date: timelineStartDate,
                                 character: configuration.character,
                                 skillQueue: remainingEntries.map({ .init(skillName: $0.name,
                                                                          startDate: $0.startDate,
                                                                          finishDate: $0.finishDate) })))
        }
        
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
        
        if entries.isEmpty {
            entries.append(.init(date: Date(),
                                 character: configuration.character,
                                 skillQueue: []))
        }
        
        return Timeline(entries: entries, policy: .never)
    }
}

struct WidgetCharacter: AppEntity {
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Character"
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
    static var defaultQuery = WidgetCharacterQuery()
    
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
    
    init(data: ECKWidgetDataStorage.SkillQueueData) {
        self.id = data.characterId
        self.name = data.characterName
    }
    
    static var dummy: WidgetCharacter {
        return .init(id: 2123087197, name: "EVECompanion")
    }
}

struct WidgetCharacterQuery: EntityQuery {
    
    typealias Entity = WidgetCharacter
    
    func entities(for identifiers: [Entity.ID]) async throws -> [Entity] {
        var result: [Entity] = []
        
        for identifier in identifiers {
            if identifier == WidgetCharacter.dummy.id {
                result.append(.dummy)
                continue
            }
            
            guard let data = await ECKWidgetDataStorage.shared.loadSkillQueue(for: identifier) else {
                continue
            }
            
            result.append(.init(data: data))
        }
        
        return result
    }
    
    func suggestedEntities() async throws -> [Entity] {
        let skillQueues = await ECKWidgetDataStorage.shared.loadAllSkillQueues()
        return skillQueues.map({ .init(data: $0) })
    }
    
}

struct SkillQueueWidgetTimelineEntry: TimelineEntry {
    
    let date: Date
    
    let character: WidgetCharacter
    let skillQueue: [SkillQueueEntry]
    
    static var dummy1: SkillQueueWidgetTimelineEntry = {
        let dummy1Skill = SkillQueueEntry.dummy1
        return .init(date: dummy1Skill.startDate!,
                     character: .dummy,
                     skillQueue: [dummy1Skill, .dummy2])
    }()
    
    static var dummy2: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.startDate!,
                     character: .dummy,
                     skillQueue: [.dummy2])
    }()
    
    static var dummy3: SkillQueueWidgetTimelineEntry = {
        return .init(date: SkillQueueEntry.dummy2.finishDate!,
                     character: .dummy,
                     skillQueue: [])
    }()
}

struct SkillQueueEntry: Identifiable {
    
    var id: String {
        return skillName
    }
    
    let skillName: String
    let startDate: Date?
    let finishDate: Date?
    
    static var dummy1: SkillQueueEntry = {
        return .init(skillName: "Amarr Titan IV",
                     startDate: Date() - 3600,
                     finishDate: Date() + 5)
    }()
    
    static var dummy2: SkillQueueEntry = {
        return .init(skillName: "Amarr Titan V",
                     startDate: dummy1.finishDate,
                     finishDate: dummy1.finishDate! + 5)
    }()
}

struct EVECompanionWidgetsEntryView: View {
    var entry: Provider.Entry
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
        
        if let finishDate = skill.finishDate,
           widgetFamily != .systemMedium {
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
            
            Text(entry.character.name)
                .bold()
                .font(.title2)
            
            Spacer()
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
                .containerBackground(.background,
                                     for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
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

#Preview(as: .systemMedium) {
    EVECompanionWidgets()
} timeline: {
    SkillQueueWidgetTimelineEntry.dummy1
    SkillQueueWidgetTimelineEntry.dummy2
    SkillQueueWidgetTimelineEntry.dummy3
}
