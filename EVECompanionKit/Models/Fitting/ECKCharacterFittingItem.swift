//
//  ECKCharacterFittingItem.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation

public class ECKCharacterFittingItem: Decodable, Hashable {
    
    private enum CodingKeys: String, CodingKey {
        case flag
        case quantity
        case item = "type_id"
    }
    
    public let flag: ECKItemLocationFlag
    public let quantity: Int
    public let item: ECKItem
    
    internal var attributes: [ECKCharacterFitting.AttributeID: ECKFittingAttribute] = [:]
    
    public static func == (lhs: ECKCharacterFittingItem, rhs: ECKCharacterFittingItem) -> Bool {
        return lhs.flag == rhs.flag
        && lhs.quantity == rhs.quantity
        && lhs.item == rhs.item
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(flag)
        hasher.combine(quantity)
        hasher.combine(item)
    }
    
}
