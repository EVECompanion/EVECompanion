//
//  ECKAsset.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 24.06.24.
//

import Foundation

public final class ECKAsset: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case isBlueprintCopy = "is_blueprint_copy"
        case isSingleton = "is_singleton"
        case itemId = "item_id"
        case locationFlag = "location_flag"
        case quantity
        case item = "type_id"
    }
    
    public let isBlueprintCopy: Bool?
    public let isSingleton: Bool
    public let itemId: Int
    public let locationFlag: ECKItemLocationFlag
    public internal(set) var location: ECKAssetLocation
    public let quantity: Int
    public let item: ECKItem
    
    public var customName: String?
    public var children: [ECKAsset]? {
        if contains.isEmpty {
            return nil
        } else {
            return contains
        }
    }
    public var contains: [ECKAsset] = []
    public var containedIn: ECKAsset?
    
    public let id: UUID = .init()
    
    public var formattedItemName: String {
        if isBlueprintCopy ?? false {
            return "\(item.name) Copy"
        } else {
            return item.name
        }
    }
    
    public static let dummyAvatar: ECKAsset = {
        let doomsday = ECKAsset(isBlueprintCopy: nil,
                                isSingleton: true,
                                itemId: 1,
                                locationFlag: .Cargo,
                                location: .item(itemId: 0),
                                quantity: 1,
                                item: .init(typeId: 24550),
                                customName: nil,
                                contains: [],
                                containedIn: nil)
        
        let jumpBridge = ECKAsset(isBlueprintCopy: nil,
                                  isSingleton: true,
                                  itemId: 2,
                                  locationFlag: .Cargo,
                                  location: .item(itemId: 0),
                                  quantity: 1,
                                  item: .init(typeId: 23953),
                                  customName: nil,
                                  contains: [],
                                  containedIn: nil)
        
        let avatar = ECKAsset(isBlueprintCopy: nil,
                              isSingleton: true,
                              itemId: 0,
                              locationFlag: .Hangar,
                              location: .station(.jita),
                              quantity: 1,
                              item: .init(typeId: 11567),
                              customName: "EVECompanion's Avatar",
                              contains: [doomsday, jumpBridge],
                              containedIn: nil)
        
        doomsday.containedIn = avatar
        jumpBridge.containedIn = avatar
        
        return avatar
    }()
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isBlueprintCopy = try container.decodeIfPresent(Bool.self, forKey: .isBlueprintCopy)
        self.isSingleton = try container.decode(Bool.self, forKey: .isSingleton)
        self.itemId = try container.decode(Int.self, forKey: .itemId)
        self.item = try container.decode(ECKItem.self, forKey: .item)
        self.location = try ECKAssetLocation(from: decoder)
        self.locationFlag = try container.decode(ECKItemLocationFlag.self, forKey: .locationFlag)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
    }
    
    init(isBlueprintCopy: Bool?, 
         isSingleton: Bool,
         itemId: Int,
         locationFlag: ECKItemLocationFlag,
         location: ECKAssetLocation,
         quantity: Int,
         item: ECKItem,
         customName: String?,
         contains: [ECKAsset],
         containedIn: ECKAsset?) {
        self.isBlueprintCopy = isBlueprintCopy
        self.isSingleton = isSingleton
        self.itemId = itemId
        self.locationFlag = locationFlag
        self.location = location
        self.quantity = quantity
        self.item = item
        self.customName = customName
        self.contains = contains
        self.containedIn = containedIn
    }
    
    internal func isSearchResult(for text: String) -> Bool {
        if item.name.lowercased().contains(text.lowercased()) {
            return true
        }
        
        if let customName,
           customName.isEmpty == false,
           customName.lowercased().contains(text.lowercased()) {
            return true
        }
        
        return false
    }
    
    internal func includeInSearch(for text: String) -> Bool {
        return isSearchResult(for: text) || contains.filter { asset in
            asset.includeInSearch(for: text)
        }.isEmpty == false
    }
    
    internal func filteredChildren(for text: String, includeAllChildren: Bool = false) -> [ECKAsset] {
        guard let children else {
            return []
        }
        
        guard includeAllChildren == false else {
            return children.map { $0.copy() }
        }
        
        return children.compactMap { asset -> ECKAsset? in
            let include = asset.includeInSearch(for: text)
            
            if include {
                let assetCopy = asset.copy()
                let assetIsSearchResult = assetCopy.isSearchResult(for: text)
                assetCopy.contains = assetCopy.filteredChildren(for: text, includeAllChildren: assetIsSearchResult)
                return assetCopy
            } else {
                return nil
            }
        }
    }
    
    internal func copy() -> ECKAsset {
        return .init(isBlueprintCopy: isBlueprintCopy,
                     isSingleton: isSingleton,
                     itemId: itemId,
                     locationFlag: locationFlag,
                     location: location,
                     quantity: quantity,
                     item: item,
                     customName: customName,
                     contains: contains.map({ asset in
                        let newAsset = asset.copy()
                        newAsset.containedIn = self
                        return newAsset
                     }),
                     containedIn: containedIn)
    }
    
}
