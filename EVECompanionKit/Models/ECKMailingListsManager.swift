//
//  ECKMailingListsManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

actor ECKMailingListManager {
    
    static let shared = ECKMailingListManager()
    private let cacheLifetime: TimeInterval = .fromMinutes(minutes: 10)
    
    private var mailingListsByCharacterId: [Int: CacheEntry] = [:]
    private var mailingListTasks: [Int: Task<[ECKMailingList], any Error>] = [:]
    
    private init() { }
    
    func get(token: ECKToken) async throws(ECKWebError) -> [ECKMailingList] {
        if let cacheEntry = mailingListsByCharacterId[token.characterId],
           cacheEntry.date + cacheLifetime > Date() {
            return cacheEntry.mailingLists
        }
        
        if let mailingListTask = mailingListTasks[token.characterId] {
            do {
                return try await mailingListTask.value
            } catch let error as ECKWebError {
                throw error
            } catch {
                throw .unknownError
            }
        }
        
        let task: Task<[ECKMailingList], any Error> = Task {
            try await ECKWebService().loadResource(resource: ECKFetchMailingListsResource(token: token)).response
        }
        mailingListTasks[token.characterId] = task
        
        do {
            let mailingLists = try await task.value
            mailingListsByCharacterId[token.characterId] = .init(date: Date(),
                                                                 mailingLists: mailingLists)
            mailingListTasks[token.characterId] = nil
            return mailingLists
        } catch let error as ECKWebError {
            mailingListTasks[token.characterId] = nil
            throw error
        } catch {
            mailingListTasks[token.characterId] = nil
            throw .unknownError
        }
    }
    
    private struct CacheEntry {
        let date: Date
        let mailingLists: [ECKMailingList]
    }
}
