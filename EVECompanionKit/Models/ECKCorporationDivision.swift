//
//  ECKCorporationDivision.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.04.26.
//

import Foundation

public struct ECKCorporationDivision: Decodable, Identifiable, Sendable {
    
    public let division: Int
    public let name: String?
    
    public var id: Int {
        division
    }
    
    enum CodingKeys: CodingKey {
        case division
        case name
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.division = try container.decode(Int.self, forKey: .division)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
    
    init(division: Int, name: String?) {
        self.division = division
        self.name = name
    }
    
}
