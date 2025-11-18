//
//  ECKCharacterMarketOrder.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public final class ECKCharacterMarketOrder: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case duration
        case escrow
        case isBuyOrder = "is_buy_order"
        case isCorporation = "is_corporation"
        case issued
        case station = "location_id"
        case minVolume = "min_volume"
        case orderId = "order_id"
        case price
        case region = "region_id"
        case item = "type_id"
        case volumeRemain = "volume_remain"
        case volumeTotal = "volume_total"
    }
    
    public static let dummy1: ECKCharacterMarketOrder = .init(duration: 30,
                                                              escrow: nil,
                                                              isBuyOrder: false,
                                                              isCorporation: false,
                                                              issued: Date() - .fromHours(hours: 5),
                                                              station: .init(stationId: 60003760, token: .dummy),
                                                              minVolume: nil,
                                                              orderId: 0,
                                                              price: 150_000_000,
                                                              region: .init(regionId: 10000002),
                                                              item: .init(typeId: 12729),
                                                              volumeRemain: 3,
                                                              volumeTotal: 5)
    
    public static let dummy2: ECKCharacterMarketOrder = .init(duration: 30,
                                                              escrow: nil,
                                                              isBuyOrder: true,
                                                              isCorporation: false,
                                                              issued: Date() - .fromHours(hours: 23),
                                                              station: .init(stationId: 60003760, token: .dummy),
                                                              minVolume: nil,
                                                              orderId: 0,
                                                              price: 260_000_000,
                                                              region: .init(regionId: 10000002),
                                                              item: .init(typeId: 22436),
                                                              volumeRemain: 3,
                                                              volumeTotal: 5)
    
    public let duration: Int
    public let escrow: Double?
    public let isBuyOrder: Bool
    public let isCorporation: Bool
    public let issued: Date
    public let station: ECKStation
    public let minVolume: Int?
    public let orderId: Int
    public let price: Double
    public let region: ECKRegion
    public let item: ECKItem
    public let volumeRemain: Int
    public let volumeTotal: Int
    
    public var id: Int {
        return orderId
    }
    
    init(duration: Int,
         escrow: Double?,
         isBuyOrder: Bool,
         isCorporation: Bool,
         issued: Date,
         station: ECKStation,
         minVolume: Int?,
         orderId: Int,
         price: Double,
         region: ECKRegion,
         item: ECKItem,
         volumeRemain: Int,
         volumeTotal: Int) {
        self.duration = duration
        self.escrow = escrow
        self.isBuyOrder = isBuyOrder
        self.isCorporation = isCorporation
        self.issued = issued
        self.station = station
        self.minVolume = minVolume
        self.orderId = orderId
        self.price = price
        self.region = region
        self.item = item
        self.volumeRemain = volumeRemain
        self.volumeTotal = volumeTotal
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.escrow = try container.decodeIfPresent(Double.self, forKey: .escrow)
        self.isBuyOrder = try container.decodeIfPresent(Bool.self, forKey: .isBuyOrder) ?? false
        self.isCorporation = try container.decode(Bool.self, forKey: .isCorporation)
        self.issued = try container.decode(Date.self, forKey: .issued)
        self.station = try container.decode(ECKStation.self, forKey: .station)
        self.minVolume = try container.decodeIfPresent(Int.self, forKey: .minVolume)
        self.orderId = try container.decode(Int.self, forKey: .orderId)
        self.price = try container.decode(Double.self, forKey: .price)
        self.region = try container.decode(ECKRegion.self, forKey: .region)
        self.item = try container.decode(ECKItem.self, forKey: .item)
        self.volumeRemain = try container.decode(Int.self, forKey: .volumeRemain)
        self.volumeTotal = try container.decode(Int.self, forKey: .volumeTotal)
    }
    
}
