//
//  ECKMarketOrder.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.11.25.
//

import Foundation

public final class ECKMarketOrder: Decodable, Identifiable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case duration
        case isBuyOrder = "is_buy_order"
        case issued
        case station = "location_id"
        case minVolume = "min_volume"
        case orderId = "order_id"
        case price
        case volumeRemain = "volume_remain"
        case volumeTotal = "volume_total"
    }
    
    public let duration: Int
    public let isBuyOrder: Bool
    public let issued: Date
    public let station: ECKStation
    public let minVolume: Int
    public let orderId: Int
    public let price: Double
    public let volumeRemain: Int
    public let volumeTotal: Int
    
    public var id: Int {
        return orderId
    }
    
    init(duration: Int,
         isBuyOrder: Bool,
         issued: Date,
         station: ECKStation,
         minVolume: Int,
         orderId: Int,
         price: Double,
         volumeRemain: Int,
         volumeTotal: Int) {
        self.duration = duration
        self.isBuyOrder = isBuyOrder
        self.issued = issued
        self.station = station
        self.minVolume = minVolume
        self.orderId = orderId
        self.price = price
        self.volumeRemain = volumeRemain
        self.volumeTotal = volumeTotal
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.isBuyOrder = try container.decode(Bool.self, forKey: .isBuyOrder)
        self.issued = try container.decode(Date.self, forKey: .issued)
        self.station = try container.decode(ECKStation.self, forKey: .station)
        self.minVolume = try container.decode(Int.self, forKey: .minVolume)
        self.orderId = try container.decode(Int.self, forKey: .orderId)
        self.price = try container.decode(Double.self, forKey: .price)
        self.volumeRemain = try container.decode(Int.self, forKey: .volumeRemain)
        self.volumeTotal = try container.decode(Int.self, forKey: .volumeTotal)
    }
    
    public static func == (lhs: ECKMarketOrder, rhs: ECKMarketOrder) -> Bool {
        return lhs.duration == rhs.duration
        && lhs.isBuyOrder == rhs.isBuyOrder
        && lhs.issued == rhs.issued
        && lhs.station.stationId == rhs.station.stationId
        && lhs.minVolume == rhs.minVolume
        && lhs.orderId == rhs.orderId
        && lhs.price == rhs.price
        && lhs.volumeRemain == rhs.volumeRemain
        && lhs.volumeTotal == rhs.volumeTotal
    }
    
}
