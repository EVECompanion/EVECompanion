//
//  ECKMailRecipientSearchResult.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import Foundation

public struct ECKMailRecipientSearchResult: Identifiable, Equatable, Sendable {
    
    public var id: String {
        "\(recipient.recipientType.rawValue)-\(recipient.recipientId)"
    }
    
    public let recipient: ECKMailRecipient
    public let name: String
    
    public var recipientType: ECKMailRecipient.ECKRecipientType {
        recipient.recipientType
    }
    
    public init(recipient: ECKMailRecipient, name: String) {
        self.recipient = recipient
        self.name = name
    }
}
