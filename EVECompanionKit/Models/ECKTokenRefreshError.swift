//
//  ECKTokenRefreshError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 01.07.24.
//

import Foundation

internal class ECKTokenRefreshError: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
    
    let error: String?
    let errorDescription: String?
    
}
