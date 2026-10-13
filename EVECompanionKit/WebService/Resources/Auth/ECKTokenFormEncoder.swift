//
//  ECKTokenFormEncoder.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 13.10.26.
//

import Foundation
import Alamofire

enum ECKOAuthTokenFormEncoder {
    static func encode(_ parameters: [String: String]) -> Data {
        let encoder = URLEncodedFormEncoder(
            alphabetizeKeyValuePairs: true,
            spaceEncoding: .plusReplaced
        )

        do {
            return Data(try encoder.encode(parameters).utf8)
        } catch {
            preconditionFailure("Failed to encode OAuth token request form: \(error)")
        }
    }
}
