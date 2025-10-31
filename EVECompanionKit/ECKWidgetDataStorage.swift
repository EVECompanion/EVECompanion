//
//  ECKWidgetDataStorage.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.10.25.
//

import Foundation

public actor ECKWidgetDataStorage {
    
    public static let shared: ECKWidgetDataStorage = .init()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum DataType {
        case skillQueue
        
        var filePrefix: String {
            switch self {
            case .skillQueue:
                return "skillQueue"
            }
        }
    }
    
    enum WidgetDataError: Error {
        case sharedDirectoryURL
    }
    
    public struct SkillQueueData: Codable {
        public struct SkillQueueEntry: Codable {
            public let name: String
            public let startDate: Date?
            public let finishDate: Date?
        }
        
        public let characterId: Int
        public let characterName: String
        public let skillQueue: [SkillQueueEntry]
    }
    
    private var appGroupContainerURL: URL? {
        FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: ECKAppVariant.current.appGroupIdentifier)
    }
    
    private init() { }
    
    public func storeSkillQueue(_ queue: ECKCharacterSkillQueue, for character: ECKCharacter) {
        do {
            logger.info("Storing skillqueue for character \(character.id)")
            let data = SkillQueueData(characterId: character.id,
                                      characterName: character.name,
                                      skillQueue: queue.currentEntries.map({ .init(name: "\($0.skill.name) \(ECFormatters.skillLevel(level: $0.finishLevel))",
                                                                                   startDate: $0.startDate,
                                                                                   finishDate: $0.finishDate) }))
            try saveData(data, dataType: .skillQueue, characterId: character.id)
        } catch {
            logger.error("Error saving skillqueue data for widgets: \(error)")
        }
    }
    
    public func removeSkillQueue(for characterId: Int) {
        logger.info("Removing stored skillqueue for character \(characterId)")
        
        do {
            try removeData(dataType: .skillQueue, characterId: characterId)
        } catch {
            logger.error("Error removing skillqueue for character \(characterId)")
        }
    }
    
    public func loadAllSkillQueues() -> [SkillQueueData] {
        let skillQueueFiles = listFiles(for: .skillQueue)
        let data: [SkillQueueData] = skillQueueFiles.compactMap({ try? loadData($0) })
        return data.sorted(by: { $0.characterName < $1.characterName })
    }
    
    private func listFiles(for dataType: DataType) -> [URL] {
        guard let appGroupContainerURL else {
            logger.error("Cannot get shared container url.")
            return []
        }
        
        do {
            let documents = try FileManager.default.contentsOfDirectory(at: appGroupContainerURL, includingPropertiesForKeys: nil)
            let filteredDocuments = documents.filter({ $0.lastPathComponent.starts(with: "\(dataType.filePrefix)-") })
            return filteredDocuments
        } catch {
            logger.error("Error listing skill queues: \(error)")
            return []
        }
    }
    
    public func loadSkillQueue(for characterId: Int) -> SkillQueueData? {
        do {
            logger.info("Loading skillqueue for character \(characterId)")
            return try loadData(dataType: .skillQueue, characterId: characterId)
        } catch {
            logger.error("Error loading skillqueue data for widgets: \(error)")
            return nil
        }
    }
    
    private func buildFileURL(dataType: DataType, characterId: Int) -> URL? {
        return appGroupContainerURL?.appending(path: "\(dataType.filePrefix)-\(characterId).json")
    }
    
    private func saveData(_ data: any Encodable, dataType: DataType, characterId: Int) throws {
        guard let url = buildFileURL(dataType: dataType, characterId: characterId) else {
            logger.error("Cannot get shared container url.")
            throw WidgetDataError.sharedDirectoryURL
        }
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url, options: .atomic)
    }
    
    private func loadData<DecodeTo: Decodable>(dataType: DataType, characterId: Int) throws -> DecodeTo {
        guard let url = buildFileURL(dataType: dataType, characterId: characterId) else {
            logger.error("Cannot get shared container url.")
            throw WidgetDataError.sharedDirectoryURL
        }
        
        return try loadData(url)
    }
    
    private func removeData(dataType: DataType, characterId: Int) throws {
        guard let url = buildFileURL(dataType: dataType, characterId: characterId) else {
            logger.error("Cannot get shared container url.")
            throw WidgetDataError.sharedDirectoryURL
        }
        
        try FileManager.default.removeItem(at: url)
    }
    
    private func loadData<DecodeTo: Decodable>(_ url: URL) throws -> DecodeTo {
        do {
            let data = try Data(contentsOf: url)
            let result = try decoder.decode(DecodeTo.self, from: data)
            return result
        } catch {
            logger.error("Error loading widget data: \(error)")
            throw error
        }
    }
    
}
