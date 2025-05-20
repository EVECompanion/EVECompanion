//
//  ECKAPIError.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 07.05.24.
//

import Foundation

enum ECKAPIError: Error {
    
    case generic
    case codeNotSet
    case stateMismatch
    case characterIdUnknown
    case tokenRefresh
    case tokenInvalid
    
}
