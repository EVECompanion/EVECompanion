//
//  ECKIndustryActivity.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import Foundation
public import UIKit

public enum ECKIndustryJobType: Int, CaseIterable, Identifiable, Sendable {
    case manufacturing = 1
    case researchTE = 3
    case researchME = 4
    case copying = 5
    case invention = 8
    case reaction = 9
    
    public var id: Int { rawValue }
    
    public var color: UIColor {
        switch self {
        case .manufacturing:
            return .systemBlue
        case .researchTE:
            return .systemCyan
        case .researchME:
            return .systemGreen
        case .copying:
            return .systemYellow
        case .invention:
            return .systemPurple
        case .reaction:
            return .systemOrange
        }
    }
    
    public init?(activityId: Int) {
        self.init(rawValue: activityId)
    }
    
}

public class ECKIndustryActivity: Decodable {
    
    public let activityId: Int
    public let name: String
    public let icon: String?
    public let description: String
    public var jobType: ECKIndustryJobType? {
        ECKIndustryJobType(activityId: activityId)
    }
    
    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let activityId = try container.decode(Int.self)
        self.init(activityId: activityId)
    }
    
    convenience init(activityId: Int) {
        let activityData = ECKSDEManager.shared.getIndustryActivity(activityId: activityId)
        self.init(activityId: activityId, activityData: activityData)
    }
    
    init(activityId: Int, activityData: ECKSDEManager.FetchedIndustryActivity) {
        self.activityId = activityId
        self.name = activityData.name
        self.icon = activityData.icon
        self.description = activityData.description
    }
    
}
