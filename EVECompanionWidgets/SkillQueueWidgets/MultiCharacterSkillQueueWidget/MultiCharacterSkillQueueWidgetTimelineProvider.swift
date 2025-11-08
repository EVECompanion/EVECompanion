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
        
        let baseDate = Date()
        
        var entries: [MultiCharacterSkillQueueWidgetTimelineEntry] = []
        
        var data: [ECKWidgetDataStorage.SkillQueueData] = []
        
        for character in configuration.characters {
            let skillQueue = await ECKWidgetDataStorage.shared.loadSkillQueue(for: character.id)
            data.append((skillQueue ?? .init(characterId: character.id,
                                             characterName: character.name,
                                             skillQueue: [])))
        }
        
        while data.compactMap({ $0.skillQueue }).isEmpty == false {
            // Find the next completion date from all the skill queues
            guard let nextDate = data.compactMap({ $0.skillQueue.first?.finishDate }).min() else {
                break
            }
            
            guard let affectedCharacterIndex = data.firstIndex(where: { $0.skillQueue.first?.finishDate == nextDate }) else {
                logger.error("Cannot find character for finish date \(nextDate)")
                break
            }
            
            entries.append(.init(entries: data.map({ data in
                return .init(date: data.skillQueue.first?.finishDate ?? baseDate,
                             character: .init(id: data.characterId, name: data.characterName),
                             skillQueue: data.skillQueue.map({ .init(skillName: $0.name, startDate: $0.startDate, finishDate: $0.finishDate) }))
            })))
            
            data[affectedCharacterIndex] = .init(characterId: data[affectedCharacterIndex].characterId,
                                                 characterName: data[affectedCharacterIndex].characterName,
                                                 skillQueue: Array(data[affectedCharacterIndex].skillQueue.dropFirst()))
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
        
        if entries.isEmpty {
            for character in configuration.characters {
                entries.append(.init(entries: [.init(date: baseDate, character: character, skillQueue: [])]))
            }
        }
        
        return Timeline(entries: entries, policy: .never)
    }
}
