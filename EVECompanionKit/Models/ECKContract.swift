//
//  ECKContract.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 11.05.24.
//

import Foundation
public import SwiftUI

public class ECKContract: Decodable, Identifiable, ObservableObject {
    
    private enum CodingKeys: String, CodingKey {
        case acceptorId = "acceptor_id"
        case assigneeId = "assignee_id"
        case availability
        case buyout
        case collateral
        case contractId = "contract_id"
        case dateAccepted = "date_accepted"
        case dateCompleted = "date_completed"
        case dateExpired = "date_expired"
        case dateIssued = "date_issued"
        case daysToComplete = "days_to_complete"
        case endLocationId = "end_location_id"
        case forCorporation = "for_corporation"
        case issuerCorporationId = "issuer_corporation_id"
        case issuerId = "issuer_id"
        case price
        case reward
        case startLocationId = "start_location_id"
        case status
        case title
        case type
        case volume
    }
    
    public enum ECKContractAvailability: String, Decodable {
        case `public`
        case personal
        case corporation
        case alliance
        
        public var title: String {
            switch self {
            case .public:
                return "Public"
            case .personal:
                return "Personal"
            case .corporation:
                return "Corporation"
            case .alliance:
                return "Alliance"
            }
        }
    }
    
    public enum ECKContractType: String, Decodable {
        case unknown
        case itemExchange = "item_exchange"
        case auction
        case courier
        case loan
        
        public var title: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .itemExchange:
                return "Item Exchange"
            case .auction:
                return "Auction"
            case .courier:
                return "Courier"
            case .loan:
                return "Loan"
            }
        }
    }
    
    public enum ECKContractStatus: String, Decodable {
        case outstanding
        case inProgress = "in_progress"
        case finishedIssuer = "finished_issuer"
        case finishedContractor = "finished_contractor"
        case finished
        case cancelled
        case rejected
        case failed
        case deleted
        case reversed
        
        public var title: String {
            switch self {
            case .outstanding:
                return "Outstanding"
            case .inProgress:
                return "In Progress"
            case .finishedIssuer,
                 .finishedContractor,
                 .finished:
                return "Finished"
            case .cancelled:
                return "Cancelled"
            case .rejected:
                return "Rejected"
            case .failed:
                return "Failed"
            case .deleted:
                return "Deleted"
            case .reversed:
                return "Reversed"
            }
        }
        
        public var foregroundColor: Color {
            switch self {
            case .outstanding,
                 .reversed:
                return .primary
            case .inProgress:
                return .blue
            case .finishedIssuer,
                 .finishedContractor,
                 .finished,
                 .cancelled,
                 .deleted:
                return .secondary
            case .rejected,
                 .failed:
                return .red
            }
        }
    }
    
    public var id: Int {
        return contractId
    }
    
    public static var dummyItemExchangeOutstanding: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .personal,
                     buyout: nil,
                     collateral: nil,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: nil,
                     dateCompleted: nil,
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date(),
                     daysToComplete: nil,
                     endLocationId: nil,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: 15000000,
                     reward: nil,
                     startLocationId: 60008494,
                     status: .outstanding,
                     title: nil,
                     type: .itemExchange,
                     volume: nil,
                     token: .dummy)
    }
    
    public static var dummyItemExchangeFinished: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .personal,
                     buyout: nil,
                     collateral: nil,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: Date(),
                     dateCompleted: Date(),
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date() - TimeInterval.fromDays(days: 1),
                     daysToComplete: nil,
                     endLocationId: nil,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: 15_000_000,
                     reward: nil,
                     startLocationId: 60008494,
                     status: .finished,
                     title: nil,
                     type: .itemExchange,
                     volume: nil,
                     token: .dummy)
    }
    
    public static var dummyCourierOutstanding: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .public,
                     buyout: nil,
                     collateral: 5_000_000_000,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: nil,
                     dateCompleted: nil,
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date(),
                     daysToComplete: 2,
                     endLocationId: 60008494,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: nil,
                     reward: 20_000_000,
                     startLocationId: 60003760,
                     status: .outstanding,
                     title: nil,
                     type: .courier,
                     volume: 20_132,
                     token: .dummy)
    }
    
    public static var dummyCourierInProgress: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .public,
                     buyout: nil,
                     collateral: 5_000_000_000,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: Date() - TimeInterval.fromHours(hours: 5),
                     dateCompleted: nil,
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date(),
                     daysToComplete: 2,
                     endLocationId: 60008494,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: nil,
                     reward: 20_000_000,
                     startLocationId: 60003760,
                     status: .inProgress,
                     title: "Please move my stuff",
                     type: .courier,
                     volume: 20_132,
                     token: .dummy)
    }
    
    public static var dummyCourierCompleted: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .public,
                     buyout: nil,
                     collateral: 5_000_000_000,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: Date() - TimeInterval.fromHours(hours: 5),
                     dateCompleted: Date(),
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date(),
                     daysToComplete: 2,
                     endLocationId: 60008494,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: nil,
                     reward: 20_000_000,
                     startLocationId: 60003760,
                     status: .finished,
                     title: "Some courier contract",
                     type: .courier,
                     volume: 20_132,
                     token: .dummy)
    }
    
    public static var dummyCourierFailed: ECKContract {
        return .init(acceptorId: 0,
                     assigneeId: 1,
                     availability: .public,
                     buyout: nil,
                     collateral: 5_000_000_000,
                     contractId: .random(in: 0..<1000),
                     dateAccepted: Date() - TimeInterval.fromHours(hours: 5),
                     dateCompleted: Date(),
                     dateExpired: Date() + TimeInterval.fromDays(days: 2),
                     dateIssued: Date(),
                     daysToComplete: 2,
                     endLocationId: 60008494,
                     forCorporation: false,
                     issuerCorporationId: 3,
                     issuerId: 4,
                     price: nil,
                     reward: 20_000_000,
                     startLocationId: 60003760,
                     status: .failed,
                     title: "Some other courier contract",
                     type: .courier,
                     volume: 20_132,
                     token: .dummy)
    }
    
    let acceptorId: Int
    let assigneeId: Int
    public let availability: ECKContractAvailability
    public let buyout: Double?
    public let collateral: Double?
    public let contractId: Int
    public let dateAccepted: Date?
    public let dateCompleted: Date?
    public let dateExpired: Date
    public let dateIssued: Date
    public let daysToComplete: Int?
    @NestedObservableObject public var endLocation: ECKStation = .unknown
    public let forCorporation: Bool
    let issuerCorporationId: Int
    let issuerId: Int
    public let price: Double?
    public let reward: Double?
    @NestedObservableObject  public var startLocation: ECKStation = .unknown
    public let status: ECKContractStatus
    public let title: String?
    public let type: ECKContractType
    public let volume: Double?
    
    private init(acceptorId: Int,
                 assigneeId: Int,
                 availability: ECKContractAvailability,
                 buyout: Double?,
                 collateral: Double?,
                 contractId: Int,
                 dateAccepted: Date?,
                 dateCompleted: Date?,
                 dateExpired: Date,
                 dateIssued: Date,
                 daysToComplete: Int?,
                 endLocationId: Int?,
                 forCorporation: Bool,
                 issuerCorporationId: Int,
                 issuerId: Int,
                 price: Double?,
                 reward: Double?,
                 startLocationId: Int?,
                 status: ECKContractStatus,
                 title: String?,
                 type: ECKContractType,
                 volume: Double?,
                 token: ECKToken) {
        self.acceptorId = acceptorId
        self.assigneeId = assigneeId
        self.availability = availability
        self.buyout = buyout
        self.collateral = collateral
        self.contractId = contractId
        self.dateAccepted = dateAccepted
        self.dateCompleted = dateCompleted
        self.dateExpired = dateExpired
        self.dateIssued = dateIssued
        self.daysToComplete = daysToComplete
        if let endLocationId {
            self.endLocation = .init(stationId: endLocationId, token: token)
        } else {
            self.endLocation = .unknown
        }
        self.forCorporation = forCorporation
        self.issuerCorporationId = issuerCorporationId
        self.issuerId = issuerId
        self.price = price
        self.reward = reward
        if let startLocationId {
            self.startLocation = .init(stationId: startLocationId, token: token)
        } else {
            self.startLocation = .unknown
        }
        self.status = status
        self.title = title
        self.type = type
        self.volume = volume
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.acceptorId = try container.decode(Int.self, forKey: .acceptorId)
        self.assigneeId = try container.decode(Int.self, forKey: .assigneeId)
        self.availability = try container.decode(ECKContract.ECKContractAvailability.self, forKey: .availability)
        self.buyout = try container.decodeIfPresent(Double.self, forKey: .buyout)
        self.collateral = try container.decodeIfPresent(Double.self, forKey: .collateral)
        self.contractId = try container.decode(Int.self, forKey: .contractId)
        self.dateAccepted = try container.decodeIfPresent(Date.self, forKey: .dateAccepted)
        self.dateCompleted = try container.decodeIfPresent(Date.self, forKey: .dateCompleted)
        self.dateExpired = try container.decode(Date.self, forKey: .dateExpired)
        self.dateIssued = try container.decode(Date.self, forKey: .dateIssued)
        self.daysToComplete = try container.decodeIfPresent(Int.self, forKey: .daysToComplete)
        
        // swiftlint:disable:next force_cast
        let token = decoder.userInfo[ECKWebService.tokenCodingUserInfoKey] as! ECKToken
        let endLocationId = try container.decodeIfPresent(Int.self, forKey: .endLocationId)
        if let endLocationId {
            self.endLocation = .init(stationId: endLocationId, token: token)
        } else {
            self.endLocation = .unknown
        }
        self.forCorporation = try container.decode(Bool.self, forKey: .forCorporation)
        self.issuerCorporationId = try container.decode(Int.self, forKey: .issuerCorporationId)
        self.issuerId = try container.decode(Int.self, forKey: .issuerId)
        self.price = try container.decodeIfPresent(Double.self, forKey: .price)
        self.reward = try container.decodeIfPresent(Double.self, forKey: .reward)
        
        let startLocationId = try container.decodeIfPresent(Int.self, forKey: .startLocationId)
        if let startLocationId {
            self.startLocation = .init(stationId: startLocationId, token: token)
        } else {
            self.startLocation = .unknown
        }
        
        self.status = try container.decode(ECKContract.ECKContractStatus.self, forKey: .status)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.type = try container.decode(ECKContract.ECKContractType.self, forKey: .type)
        self.volume = try container.decodeIfPresent(Double.self, forKey: .volume)
    }
    
}
