//
//  ECKWalletJournalEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

public class ECKWalletJournalEntry: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case amount
        case balance
        case date
        case description
        case firstPartyId = "first_party_id"
        case id
        case reason
        case refType = "ref_type"
        case secondPartyId = "second_party_id"
        case tax
        case taxReceiverId = "tax_receiver_id"
    }
    
    public let amount: Double?
    public let balance: Double?
    public let date: Date
    public let description: String
    let firstPartyId: Int?
    public let id: Int
    public let reason: String?
    public let refType: ECKWalletJournalEntryRefType
    let secondPartyId: Int?
    public let tax: Double?
    let taxReceiverId: Int?
    
    static let dummy1: ECKWalletJournalEntry = .init(amount: 70000000,
                                                     balance: 96526226.64300001,
                                                     date: .now,
                                                     description: "Someone deposited cash into your account",
                                                     firstPartyId: 2123087197,
                                                     id: 22871504961,
                                                     reason: "Apostle",
                                                     refType: .playerDonation,
                                                     secondPartyId: 2123087197,
                                                     tax: nil,
                                                     taxReceiverId: nil)
    
    static let dummy2: ECKWalletJournalEntry = .init(amount: -1869000,
                                                     balance: 31546226.643,
                                                     date: .now - .fromHours(hours: 3),
                                                     description: "Market escrow release",
                                                     firstPartyId: 2123087197,
                                                     id: 22861651795,
                                                     reason: "",
                                                     refType: .marketEscrow,
                                                     secondPartyId: 2123087197,
                                                     tax: nil,
                                                     taxReceiverId: nil)
    
    static let dummy3: ECKWalletJournalEntry = .init(amount: -958500,
                                                     balance: 33415226.643,
                                                     date: .init() - .fromHours(hours: 4),
                                                     description: "Market escrow release",
                                                     firstPartyId: 2123087197,
                                                     id: 22861651417,
                                                     reason: "",
                                                     refType: .marketEscrow,
                                                     secondPartyId: 2123087197,
                                                     tax: nil,
                                                     taxReceiverId: nil)
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        self.balance = try container.decodeIfPresent(Double.self, forKey: .balance)
        self.date = try container.decode(Date.self, forKey: .date)
        self.description = try container.decode(String.self, forKey: .description)
        self.firstPartyId = try container.decodeIfPresent(Int.self, forKey: .firstPartyId)
        self.id = try container.decode(Int.self, forKey: .id)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.refType = try container.decode(ECKWalletJournalEntryRefType.self, forKey: .refType)
        self.secondPartyId = try container.decodeIfPresent(Int.self, forKey: .secondPartyId)
        self.tax = try container.decodeIfPresent(Double.self, forKey: .tax)
        self.taxReceiverId = try container.decodeIfPresent(Int.self, forKey: .taxReceiverId)
    }
    
    init(amount: Double?, 
         balance: Double?,
         date: Date, 
         description: String,
         firstPartyId: Int?,
         id: Int,
         reason: String?,
         refType: ECKWalletJournalEntryRefType,
         secondPartyId: Int?,
         tax: Double?,
         taxReceiverId: Int?) {
        self.amount = amount
        self.balance = balance
        self.date = date
        self.description = description
        self.firstPartyId = firstPartyId
        self.id = id
        self.reason = reason
        self.refType = refType
        self.secondPartyId = secondPartyId
        self.tax = tax
        self.taxReceiverId = taxReceiverId
    }
    
}
