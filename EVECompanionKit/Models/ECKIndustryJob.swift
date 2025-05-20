//
//  ECKIndustryJob.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import Foundation

public class ECKIndustryJob: Decodable, Identifiable, ObservableObject {
    
    private enum CodingKeys: String, CodingKey {
        case activity = "activity_id"
        case blueprintId = "blueprint_id"
        case blueprintLocation = "blueprint_location_id"
        case blueprint = "blueprint_type_id"
        case duration
        case endDate = "end_date"
        case jobId = "job_id"
        case probability
        case product = "product_type_id"
        case runs
        case startDate = "start_date"
        case station = "station_id"
        case status
    }
    
    public enum Status: String, Decodable {
        case active
        case cancelled
        case delivered
        case paused
        case ready
        case reverted
        
        case unknown
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            
            guard let value = Status(rawValue: stringValue) else {
                logger.warning("Unknown Status \(stringValue)")
                self = .unknown
                return
            }
            
            self = value
        }
    }
    
    public static let dummyActive: ECKIndustryJob = .init(activity: .init(activityId: 1),
                                                          blueprintId: 0,
                                                          blueprintLocation: .init(stationId: 60003760, token: .dummy),
                                                          blueprint: .init(typeId: 992),
                                                          duration: Int(TimeInterval.fromDays(days: 7)),
                                                          endDate: Date() + .fromDays(days: 5),
                                                          jobId: 0,
                                                          probability: nil,
                                                          product: .init(typeId: 657),
                                                          runs: 5,
                                                          startDate: Date() - .fromDays(days: 2),
                                                          station: .init(stationId: 60003760, token: .dummy),
                                                          status: .active)
    
    public static let dummyPaused: ECKIndustryJob = .init(activity: .init(activityId: 5),
                                                          blueprintId: 1,
                                                          blueprintLocation: .init(stationId: 60003760, token: .dummy),
                                                          blueprint: .init(typeId: 990),
                                                          duration: Int(TimeInterval.fromDays(days: 9)),
                                                          endDate: Date() + .fromDays(days: 7),
                                                          jobId: 1,
                                                          probability: nil,
                                                          product: .init(typeId: 990),
                                                          runs: 1,
                                                          startDate: Date() - .fromDays(days: 2),
                                                          station: .init(stationId: 60003760, token: .dummy),
                                                          status: .paused)
    
    public let activity: ECKIndustryActivity
    public let blueprintId: Int
    public let blueprintLocation: ECKStation
    public let blueprint: ECKItem
    public let duration: Int
    public let endDate: Date
    public let jobId: Int
    public let probability: Float?
    public let product: ECKItem?
    public let runs: Int
    public let startDate: Date
    @NestedObservableObject public var station: ECKStation
    public let status: Status
    
    public var id: Int {
        return jobId
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.activity = try container.decode(ECKIndustryActivity.self, forKey: .activity)
        self.blueprintId = try container.decode(Int.self, forKey: .blueprintId)
        self.blueprintLocation = try container.decode(ECKStation.self, forKey: .blueprintLocation)
        self.blueprint = try container.decode(ECKItem.self, forKey: .blueprint)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.jobId = try container.decode(Int.self, forKey: .jobId)
        self.probability = try container.decodeIfPresent(Float.self, forKey: .probability)
        self.product = try container.decodeIfPresent(ECKItem.self, forKey: .product)
        self.runs = try container.decode(Int.self, forKey: .runs)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.station = try container.decode(ECKStation.self, forKey: .station)
        self.status = try container.decode(ECKIndustryJob.Status.self, forKey: .status)
    }
    
    init(activity: ECKIndustryActivity,
         blueprintId: Int,
         blueprintLocation: ECKStation,
         blueprint: ECKItem,
         duration: Int,
         endDate: Date,
         jobId: Int,
         probability: Float?,
         product: ECKItem?,
         runs: Int,
         startDate: Date,
         station: ECKStation,
         status: Status) {
        self.activity = activity
        self.blueprintId = blueprintId
        self.blueprintLocation = blueprintLocation
        self.blueprint = blueprint
        self.duration = duration
        self.endDate = endDate
        self.jobId = jobId
        self.probability = probability
        self.product = product
        self.runs = runs
        self.startDate = startDate
        self.station = station
        self.status = status
    }
    
}
