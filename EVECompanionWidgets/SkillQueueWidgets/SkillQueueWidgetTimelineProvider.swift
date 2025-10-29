//
//  SkillQueueWidgetTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 29.10.25.
//

import Foundation
import Kingfisher
import AppIntents
import WidgetKit
import EVECompanionKit

struct SkillQueueWidgetTimelineProvider: AppIntentTimelineProvider {
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
