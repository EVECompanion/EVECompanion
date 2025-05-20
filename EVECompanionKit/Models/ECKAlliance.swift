//
//  ECKAlliance.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.05.24.
//

import Foundation

final public class ECKAlliance: Decodable, Sendable, Hashable {
    
    public let name: String
    public let ticker: String
    
    public static let dummy: ECKAlliance = .init(name: "Test Alliance Please Ignore", ticker: "TEST")
    
    init(name: String, ticker: String) {
        self.name = name
        self.ticker = ticker
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(ticker)
    }
    
    public static func == (lhs: ECKAlliance, rhs: ECKAlliance) -> Bool {
        return lhs.name == rhs.name && lhs.ticker == rhs.ticker
    }
    
}
