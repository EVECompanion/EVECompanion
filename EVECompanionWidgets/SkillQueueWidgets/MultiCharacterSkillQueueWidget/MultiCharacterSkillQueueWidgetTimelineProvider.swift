//
//  MultiCharacterSkillQueueWidgetTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Jonas Schlabertz on 07.11.25.
//

import Foundation
import Kingfisher
import AppIntents
import WidgetKit
import EVECompanionKit

struct MultiCharacterSkillQueueWidgetTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MultiCharacterSkillQueueWidgetTimelineEntry {
        MultiCharacterSkillQueueWidgetTimelineEntry.dummy2
    }

    func snapshot(for configuration: MultiCharacterSkillQueueWidgetConfiguration, in context: Context) async -> MultiCharacterSkillQueueWidgetTimelineEntry {
        await timeline(for: configuration, in: context).entries.first ?? .dummy2
    }
    
    func timeline(for configuration: MultiCharacterSkillQueueWidgetConfiguration, in context: Context) async -> Timeline<MultiCharacterSkillQueueWidgetTimelineEntry> {
        guard context.isPreview == false else {
            return .init(entries: [.dummy2], policy: .never)
        }
        
        var imageResources: [any Resource] = []
        
        for character in configuration.characters {
            if let url = await ECKImageManager().loadURL(id: character.id,
                                                         category: .character,
                                                         isBPC: false) {
                imageResources.append(KF.ImageResource(downloadURL: url.appending(queryItems: [.init(name: "size", value: "512")])))
            }
        }
        
        await withCheckedContinuation { continuation in
            ImagePrefetcher(resources: imageResources, options: [
                .alsoPrefetchToMemory,
                .waitForCache,
                .cacheOriginalImage,
                .processor(ResizingImageProcessor(referenceSize: .init(width: 800, height: 800)))
            ]) { _, _, _ in
                continuation.resume()
            }.start()
        }
        
        let now = Date()
        var allData: [ECKWidgetDataStorage.SkillQueueData] = []
        
        for character in configuration.characters {
            let skillQueue = await ECKWidgetDataStorage.shared.loadSkillQueue(for: character.id)
            allData.append((skillQueue ?? .init(characterId: character.id,
                                                characterName: character.name,
                                                skillQueue: [])))
        }

        // Collect all future finish dates across all characters
        let futureFinishDates = allData
            .flatMap { $0.skillQueue }
            .compactMap(\.finishDate)
            .filter { $0 > now }
            .sorted()

        var timelineEntries: [MultiCharacterSkillQueueWidgetTimelineEntry] = [
            makeMultiCharacterEntry(for: now, allData: allData)
        ]

        for finishDate in futureFinishDates {
            timelineEntries.append(makeMultiCharacterEntry(for: finishDate, allData: allData))
        }

        if let last = futureFinishDates.last {
            timelineEntries.append(makeMultiCharacterEntry(for: last, allData: allData))
        }

        return Timeline(entries: timelineEntries, policy: .never)
    }
    
    private func makeMultiCharacterEntry(for date: Date, allData: [ECKWidgetDataStorage.SkillQueueData]) -> MultiCharacterSkillQueueWidgetTimelineEntry {
        let characterEntries = allData.map { data -> SkillQueueWidgetTimelineEntry in
            let activeOrUpcomingSkills = data.skillQueue.filter { entry in
                if let finishDate = entry.finishDate {
                    return finishDate > date
                } else {
                    return true
                }
            }

            let character = WidgetCharacter(id: data.characterId, name: data.characterName)
            return SkillQueueWidgetTimelineEntry(
                date: date,
                character: character,
                skillQueue: activeOrUpcomingSkills.map({ .init(skillName: $0.name, startDate: $0.startDate, finishDate: $0.finishDate) })
            )
        }

        return MultiCharacterSkillQueueWidgetTimelineEntry(
            date: date,
            entries: characterEntries
        )
    }
}
