//
//  ECKMarketDataManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.11.25.
//

import Foundation

public actor ECKMarketDataManager {
    
    public static let shared = ECKMarketDataManager()
    
    private class CacheEntry {
        let date: Date
        let history: [ECKMarketHistoryEntry]
        
        init(date: Date, history: [ECKMarketHistoryEntry]) {
            self.date = date
            self.history = history
        }
    }
    
    private var cache: [Int: CacheEntry] = [:]
    private var runningTasks: [Int: Task<[ECKMarketHistoryEntry], Never>] = [:]
    private let cacheTime: TimeInterval = .fromMinutes(minutes: 90)
    
    private init() {
        
    }
    
    public func marketHistoryData(forTypeId typeId: Int) async -> [ECKMarketHistoryEntry] {
        let existingEntry = cache[typeId]
        if let existingEntry,
            Date().timeIntervalSince(existingEntry.date) < cacheTime {
            logger.info("Market data cache already contains a valid entry for typeId \(typeId)")
            return existingEntry.history
        }
        
        if let runningTask = runningTasks[typeId] {
            return await runningTask.value
        }
        
        let task = Task {
            // Data in the cache is not present or outdated.
            // Request it again.
            do {
                let theForgeRegionId = 10000002
                logger.info("No Market data cached for typeId \(typeId), requesting it.")
                let marketHistoryResource = ECKMarketHistoryResource(regionId: theForgeRegionId, typeId: typeId)
                async let marketHistoryData = try await ECKWebService().loadResource(resource: marketHistoryResource)
                
                let marketHistory = try await marketHistoryData.response
                let requestDate = Date()
                let cacheEntry = CacheEntry(date: requestDate, history: marketHistory)
                self.cache[typeId] = cacheEntry
                logger.info("Cached market data for typeId \(typeId)")
                return marketHistory
            } catch {
                logger.error("Error requesting market data: \(error)")
                return []
            }
        }
        
        runningTasks[typeId] = task
        let value = await task.value
        runningTasks[typeId] = nil
        return value
    }
    
}
