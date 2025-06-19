//
//  ECKAttributeDefaultValueCache.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.25.
//

import Foundation
import Combine

actor ECKAttributeDefaultValueCache {
  
    static let shared = ECKAttributeDefaultValueCache()
    private var cache: [Int: Float] = [:]
    nonisolated(unsafe) private var subscriptions = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default
            .publisher(for: .sdeUpdated)
            .sink { _ in
                Task {
                    await self.resetCache()
                }
            }
            .store(in: &subscriptions)
    }
    
    func getDefaultValue(for attributeId: Int) -> Float? {
        if let cachedValue = cache[attributeId] {
            return cachedValue
        } else {
            guard let defaultValue = ECKSDEManager.shared.getAttributeDefaultValue(attributeId: attributeId) else {
                return nil
            }
            
            cache[attributeId] = defaultValue
            
            return defaultValue
        }
    }
    
    func resetCache() {
        cache.removeAll()
    }
    
}
