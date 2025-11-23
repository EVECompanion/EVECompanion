//
//  ECKWebError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

enum ECKWebError: Error {
    case connectionError
    case emptyResponse
    case invalidResponse
    case serverError
    case unknownError
    case statusCode(Int, Data)
    case insufficientScopes
}
