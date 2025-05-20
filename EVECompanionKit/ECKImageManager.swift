//
//  ECKImageManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.11.24.
//

import Foundation

public struct ECKImageManager {
    
    public enum Category: String {
        case alliance = "alliances"
        case corporation = "corporations"
        case character = "characters"
        case types = "types"
    }
    
    public init() {
        return
    }
    
    public func loadURL(id: Int, category: Category, isBPC: Bool?) async -> URL? {
        let variation: String
        
        switch category {
        case .alliance,
             .corporation:
            variation = "logo"
            
        case .character:
            variation = "portrait"
            
        case .types:
            if let isBPC {
                if isBPC {
                    variation = "bpc"
                } else {
                    variation = "bp"
                }
            } else {
                let fetchedVariation: String? = await loadImageVariation(id: id, category: category)
                
                guard let fetchedVariation else {
                    return nil
                }
                
                variation = fetchedVariation
            }
            
        }
        
        return URL(string: "https://images.evetech.net/\(category.rawValue)/\(id.description)/\(variation)")!
    }
    
    private func loadImageVariation(id: Int, category: Category) async -> String? {
        let resource = ECKImageInfoResource(category: category.rawValue, id: id)
        let variations: [String]
        do {
            variations = try await ECKWebService().loadResource(resource: resource).response
        } catch {
            logger.error("Error loading image info: \(error)")
            return nil
        }
        
        guard var firstVariation = variations.first else {
            return nil
        }
        
        // This is a bpo, the blueprintCopy Flag was not set.
        if firstVariation == "bpc" {
            firstVariation = "bp"
        }
        
        return firstVariation
    }
    
}
