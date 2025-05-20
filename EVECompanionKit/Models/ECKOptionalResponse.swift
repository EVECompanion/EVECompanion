//
//  ECKOptionalResponse.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 21.05.24.
//

import Foundation

class ECKOptionalResponse<ResponseType>: Decodable where ResponseType: Decodable {
    
    let response: ResponseType?
    
    required init(from decoder: any Decoder) throws {
        response = try .init(from: decoder)
    }
    
}
