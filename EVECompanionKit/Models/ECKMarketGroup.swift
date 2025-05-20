//
//  ECKMarketGroup.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 14.04.25.
//

import Foundation

public class ECKMarketGroup: Identifiable {
    
    public enum ChildType: Identifiable {
        case marketGroup(ECKMarketGroup)
        case item(ECKItem)
        
        public var id: String {
            switch self {
            case .marketGroup(let marketGroup):
                return "marketGroup.\(marketGroup.id)"
            case .item(let item):
                return "item.\(item.id)"
            }
        }
        
        public var children: [ChildType]? {
            switch self {
            case .item:
                return nil
            case .marketGroup(let marketGroup):
                return marketGroup.children
            }
        }
    }
    
    public let id: Int
    public let name: String
    public let description: String
    public let hasTypes: Bool
    public lazy var marketSubGroups: [ECKMarketGroup]? = {
        let subGroups = ECKSDEManager.shared.marketGroups(parentGroupId: id)
        if subGroups.isEmpty {
            return nil
        } else {
            return subGroups
        }
    }()
    public var children: [ChildType]? {
        if hasTypes {
            return types?.map({ .item($0) })
        } else {
            return marketSubGroups?.map({ .marketGroup($0) })
        }
    }
    
    public lazy var types: [ECKItem]? = {
        if hasTypes {
            return ECKSDEManager.shared.items(marketGroupId: id)
        } else {
            return nil
        }
    }()
    
    init(id: Int,
         name: String,
         description: String,
         hasTypes: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.hasTypes = hasTypes
    }
    
}
