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
    
    public var charge: ECKCharacterFittingItem?
    
    internal var attributes: [ECKCharacterFitting.AttributeID: ECKCharacterFitting.FittingAttribute] = [:]
    internal var state: ECKDogmaEffect.Category = .passive
    internal var maxState: ECKDogmaEffect.Category = .passive
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.flag = try container.decode(ECKItemLocationFlag.self, forKey: .flag)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.item = try container.decode(ECKItem.self, forKey: .item)
    }
    
    init(flag: ECKItemLocationFlag, quantity: Int, item: ECKItem) {
        self.flag = flag
        self.quantity = quantity
        self.item = item
    }
    
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
