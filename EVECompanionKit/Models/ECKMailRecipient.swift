//
//  ECKMailRecipient.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

public import Combine

public final class ECKMailRecipient: ObservableObject, Codable, Equatable, Sendable {
    
    enum CodingKeys: String, CodingKey {
        case recipientId = "recipient_id"
        case recipientType = "recipient_type"
    }
    
    public enum ECKRecipientType: String, Codable, Equatable, Sendable {
        case alliance
        case character
        case corporation
        case mailingList = "mailing_list"
    }
    
    public let recipientId: Int
    public let recipientType: ECKRecipientType
    
    static let dummy: ECKMailRecipient = .init(recipientId: 2123087197, 
                                               recipientType: .character)
    
    public init(recipientId: Int,
                recipientType: ECKRecipientType) {
        self.recipientId = recipientId
        self.recipientType = recipientType
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.recipientId = try container.decode(Int.self, forKey: .recipientId)
        self.recipientType = try container.decode(ECKMailRecipient.ECKRecipientType.self, forKey: .recipientType)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.recipientId, forKey: .recipientId)
        try container.encode(self.recipientType, forKey: .recipientType)
    }
    
    public static func == (lhs: ECKMailRecipient, rhs: ECKMailRecipient) -> Bool {
        return lhs.recipientId == rhs.recipientId &&
               lhs.recipientType == rhs.recipientType
    }
    
}
