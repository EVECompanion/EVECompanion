//
//  ECKSovereigntyManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.03.25.
//

import Foundation

actor ECKSovereigntyManager {
    
    static let shared: ECKSovereigntyManager = .init()
    
    private var lastRequestDate: Date = .distantPast
    private let cacheTime: TimeInterval = 3600
    private var lastEtag: String?
    private var sovUpdateTask: Task<Void, Never>?
    private var sovData: [Int: ECKSolarSystemSovereignty]?
    
    private init() {
        Task {
            await updateSovereignty()
        }
    }
    
    func sov(for system: ECKSolarSystem) async -> ECKSolarSystemSovereignty? {
        await sov(for: system.solarSystemId)
    }
    
    func sov(for systemId: Int) async -> ECKSolarSystemSovereignty? {
        await updateSovereignty()
        if let sovUpdateTask = sovUpdateTask {
            await sovUpdateTask.value
        }
        
        return sovData?[systemId]
    }
    
    private func updateSovereignty() async {
        guard sovUpdateTask == nil else {
            return
        }
        
        sovUpdateTask = Task {
            defer {
                self.sovUpdateTask = nil
            }
            
            guard lastRequestDate + cacheTime < Date() else {
                return
            }
            
            do {
                let resource = ECKSovereigntyMapResource(etag: lastEtag)
                let response = try await ECKWebService().loadResource(resource: resource)
                self.lastEtag = ((response.headers["Etag"] ?? response.headers["ETag"]) as? String)
                self.lastRequestDate = Date()
                var newData = [Int: ECKSolarSystemSovereignty]()
                response.response.forEach { sov in
                    newData[sov.systemId] = sov
                }
                self.sovData = newData
            } catch {
                logger.error("Error loading sovereignty map \(error)")
            }
        }
        
        await sovUpdateTask?.value
    }
    
}
