//
//  ECKIndustryActivity.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import Foundation

public class ECKIndustryActivity: Decodable {
    
    public let activityId: Int
    public let name: String
    public let icon: String?
    public let description: String
    
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
