//
//  ECKIndustryJob.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 19.06.24.
//

import Foundation
public import Combine

public final class ECKIndustryJob: Decodable, Identifiable, ObservableObject, @unchecked Sendable {
    
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
        case locationId = "location_id"
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
    
    public static let dummyActive: ECKIndustryJob = dummyJob(activityId: 1,
                                                             blueprintTypeId: 992,
                                                             productTypeId: 657,
                                                             durationDays: 7,
                                                             remainingDays: 5,
                                                             jobId: 0,
                                                             runs: 5,
                                                             status: .active)
    
    public static let dummyResearchTE: ECKIndustryJob = dummyJob(activityId: 3,
                                                                 blueprintTypeId: 2465,
                                                                 productTypeId: 2465,
                                                                 durationDays: 4,
                                                                 remainingDays: 1,
                                                                 jobId: 1,
                                                                 runs: 1,
                                                                 status: .active)
    
    public static let dummyResearchME: ECKIndustryJob = dummyJob(activityId: 4,
                                                                 blueprintTypeId: 25589,
                                                                 productTypeId: 25589,
                                                                 durationDays: 5,
                                                                 remainingDays: 3,
                                                                 jobId: 2,
                                                                 runs: 1,
                                                                 status: .active)
    
    public static let dummyPaused: ECKIndustryJob = dummyJob(activityId: 5,
                                                             blueprintTypeId: 990,
                                                             productTypeId: 990,
                                                             durationDays: 9,
                                                             remainingDays: 7,
                                                             jobId: 3,
                                                             runs: 1,
                                                             status: .paused)
    
    public static let dummyInvention: ECKIndustryJob = dummyJob(activityId: 8,
                                                                blueprintTypeId: 12003,
                                                                productTypeId: 20185,
                                                                durationDays: 2,
                                                                remainingDays: 1,
                                                                jobId: 4,
                                                                runs: 2,
                                                                status: .active)
    
    public static let dummyReaction: ECKIndustryJob = dummyJob(activityId: 9,
                                                               blueprintTypeId: 46155,
                                                               productTypeId: 46156,
                                                               durationDays: 3,
                                                               remainingDays: 2,
                                                               jobId: 5,
                                                               runs: 10,
                                                               status: .active)
    
    public static let dummyJobs: [ECKIndustryJob] = [
        dummyActive,
        dummyResearchTE,
        dummyResearchME,
        dummyPaused,
        dummyInvention,
        dummyReaction
    ]
    
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
        self.station = try container.decodeIfPresent(ECKStation.self, forKey: .station) ?? container.decode(ECKStation.self, forKey: .locationId)
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
    
    private static func dummyJob(activityId: Int,
                                 blueprintTypeId: Int,
                                 productTypeId: Int,
                                 durationDays: Int,
                                 remainingDays: Int,
                                 jobId: Int,
                                 runs: Int,
                                 status: Status) -> ECKIndustryJob {
        .init(activity: .init(activityId: activityId),
              blueprintId: jobId,
              blueprintLocation: .init(stationId: 60003760, token: .dummy),
              blueprint: .init(typeId: blueprintTypeId),
              duration: Int(TimeInterval.fromDays(days: Double(durationDays))),
              endDate: Date() + .fromDays(days: Double(remainingDays)),
              jobId: jobId,
              probability: nil,
              product: .init(typeId: productTypeId),
              runs: runs,
              startDate: Date() - .fromDays(days: Double(durationDays - remainingDays)),
              station: .init(stationId: 60003760, token: .dummy),
              status: status)
    }
    
}
