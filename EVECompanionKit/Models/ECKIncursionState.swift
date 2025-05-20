//
//  ECKIncursionState.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import Foundation

public enum ECKIncursionState: String, Decodable {
    
    case withdrawing
    case mobilizing
    case established
    
    case unknown
    
    public var localized: String {
        switch self {
        case .withdrawing:
            return "Withdrawing"
        case .mobilizing:
            return "Mobilizing"
        case .established:
            return "Established"
        case .unknown:
            return "Unknown"
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        guard let value = ECKIncursionState(rawValue: stringValue) else {
            logger.warning("Unknown ECKIncursionState \(stringValue)")
            self = .unknown
            return
        }
        
        self = value
    }
    
}
