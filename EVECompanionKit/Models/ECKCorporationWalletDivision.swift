//
//  ECKCorporationWalletDivision.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.04.26.
//

import Foundation

public struct ECKCorporationWalletDivision: Decodable, Identifiable, Sendable {
    
    enum CodingKeys: String, CodingKey {
        case balance
        case division
    }
    
    public let balance: Double
    public let division: Int
    
    public var id: Int {
        division
    }
    
    public var name: String {
        if division == 1 {
            return "Master Wallet"
        } else {
            return "Division \(division)"
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.balance = try container.decode(Double.self, forKey: .balance)
        self.division = try container.decode(Int.self, forKey: .division)
    }
    
    init(division: Int, balance: Double) {
        self.balance = balance
        self.division = division
    }
    
}
