//
//  ECKMarketHistoryEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 12.11.25.
//

import Foundation

public class ECKMarketHistoryEntry: Decodable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case average
        case date
        case highest
        case lowest
        case orderCount = "order_count"
        case volume
    }
    
    public let average: Float
    public let date: Date
    public let highest: Float
    public let lowest: Float
    public let orderCount: Int
    public let volume: Int
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.average = try container.decode(Float.self, forKey: .average)
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: dateString) else {
            throw ECKWebError.invalidResponse
        }
        
        self.date = date
        
        self.highest = try container.decode(Float.self, forKey: .highest)
        self.lowest = try container.decode(Float.self, forKey: .lowest)
        self.orderCount = try container.decode(Int.self, forKey: .orderCount)
        self.volume = try container.decode(Int.self, forKey: .volume)
    }
    
    public static func == (lhs: ECKMarketHistoryEntry, rhs: ECKMarketHistoryEntry) -> Bool {
        return lhs.average == rhs.average
        && lhs.date == rhs.date
        && lhs.highest == rhs.highest
        && lhs.lowest == rhs.lowest
        && lhs.orderCount == rhs.orderCount
        && lhs.volume == rhs.volume
    }
    
}
