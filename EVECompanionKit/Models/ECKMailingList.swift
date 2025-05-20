//
//  ECKMailingList.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKMailingList: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case mailingListId = "mailing_list_id"
        case name
    }
    
    let mailingListId: Int
    let name: String
    
    static let dummy: ECKMailingList = .init()
    
    private init() {
        self.mailingListId = 0
        self.name = "Unknown Mailing List"
    }
    
    init(mailingListId: Int, name: String) {
        self.mailingListId = mailingListId
        self.name = name
    }
    
}
