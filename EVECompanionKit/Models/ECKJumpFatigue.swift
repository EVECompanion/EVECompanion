//
//  ECKJumpFatigue.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.07.24.
//

import Foundation

public class ECKJumpFatigue: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case expiryDate = "jump_fatigue_expire_date"
        case lastJumpDate = "last_jump_date"
    }
    
    public let expiryDate: Date?
    public let lastJumpDate: Date?
    
    public var remainingTime: TimeInterval? {
        guard let expiryDate else {
            return nil
        }
        
        let remainingTime = expiryDate.timeIntervalSince(Date())
        
        if remainingTime < 0 {
            return nil
        } else {
            return remainingTime
        }
    }
    
    static let dummy: ECKJumpFatigue = .init(expiryDate: Date() + .fromHours(hours: 3.5), lastJumpDate: nil)
    
    init(expiryDate: Date?, lastJumpDate: Date?) {
        self.expiryDate = expiryDate
        self.lastJumpDate = lastJumpDate
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        self.lastJumpDate = try container.decodeIfPresent(Date.self, forKey: .lastJumpDate)
    }
    
}
