//
//  ECKWalletTransactionEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.24.
//

import Foundation

public final class ECKWalletTransactionEntry: Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case date
        case isBuy = "is_buy"
        case isPersonal = "is_personal"
        case journalRefId = "journal_ref_id"
        case location = "location_id"
        case quantity
        case transactionId = "transaction_id"
        case typeId = "type_id"
        case unitPrice = "unit_price"
    }
    
    public var id: Int {
        return transactionId
    }
    
    public static let dummy1: ECKWalletTransactionEntry = .init(clientId: 910158355,
                                                                date: .now - .fromHours(hours: 3),
                                                                isBuy: true,
                                                                isPersonal: true,
                                                                journalRefId: 22873580470,
                                                                location: .unknown,
                                                                quantity: 1,
                                                                transactionId: 6320986056,
                                                                item: .init(typeId: 17366),
                                                                unitPrice: 449000)
    
    public static let dummy2: ECKWalletTransactionEntry = .init(clientId: 1198327053,
                                                                date: .now - .fromHours(hours: 4),
                                                                isBuy: true,
                                                                isPersonal: true,
                                                                journalRefId: 22873383050,
                                                                location: .unknown,
                                                                quantity: 8,
                                                                transactionId: 6320944585,
                                                                item: .init(typeId: 30488),
                                                                unitPrice: 488900)
    
    let clientId: Int
    public let date: Date
    public let isBuy: Bool
    public let isPersonal: Bool
    let journalRefId: Int
    public let location: ECKStation
    public let quantity: Int
    let transactionId: Int
    public let item: ECKItem
    public let unitPrice: Double
    
    internal init(clientId: Int, date: Date, isBuy: Bool, isPersonal: Bool, journalRefId: Int, location: ECKStation, quantity: Int, transactionId: Int, item: ECKItem, unitPrice: Double) {
        self.clientId = clientId
        self.date = date
        self.isBuy = isBuy
        self.isPersonal = isPersonal
        self.journalRefId = journalRefId
        self.location = location
        self.quantity = quantity
        self.transactionId = transactionId
        self.item = item
        self.unitPrice = unitPrice
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientId = try container.decode(Int.self, forKey: .clientId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.isBuy = try container.decode(Bool.self, forKey: .isBuy)
        self.isPersonal = try container.decode(Bool.self, forKey: .isPersonal)
        self.journalRefId = try container.decode(Int.self, forKey: .journalRefId)
        self.location = try container.decode(ECKStation.self, forKey: .location)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.transactionId = try container.decode(Int.self, forKey: .transactionId)
        self.item = try container.decode(ECKItem.self, forKey: .typeId)
        self.unitPrice = try container.decode(Double.self, forKey: .unitPrice)
    }
    
}
