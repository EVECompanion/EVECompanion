//
//  ECKWebError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

public enum ECKWebError: Error, Equatable {
    case decoding
    case connectionError
    case emptyResponse
    case invalidResponse
    case serverError
    case unknownError
    case statusCode(Int, Data)
    case insufficientScopes
    case insufficientCorpRole(requiredRoles: [ECKCorporationRole])
}
