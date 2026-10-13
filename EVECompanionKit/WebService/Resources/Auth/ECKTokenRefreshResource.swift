//
//  ECKTokenRefreshResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 08.05.24.
//

import Foundation

enum ECKFormURLEncoder {

    private static let hexDigits = Array("0123456789ABCDEF".utf8)

    static func encode(_ parameters: [(name: String, value: String)]) -> Data {
        var bytes: [UInt8] = []

        for (index, parameter) in parameters.enumerated() {
            if index > 0 {
                bytes.append(UInt8(ascii: "&"))
            }

            appendFormComponent(parameter.name, to: &bytes)
            bytes.append(UInt8(ascii: "="))
            appendFormComponent(parameter.value, to: &bytes)
        }

        return Data(bytes)
    }

    private static func appendFormComponent(_ value: String, to bytes: inout [UInt8]) {
        for byte in value.utf8 {
            switch byte {
            case 0x41...0x5A, 0x61...0x7A, 0x30...0x39, 0x2A, 0x2D, 0x2E, 0x5F:
                bytes.append(byte)
            case 0x20:
                bytes.append(UInt8(ascii: "+"))
            default:
                bytes.append(UInt8(ascii: "%"))
                bytes.append(hexDigits[Int(byte >> 4)])
                bytes.append(hexDigits[Int(byte & 0x0F)])
            }
        }
    }
}

class ECKTokenRefreshResource: ECKWebResource<ECKToken>, @unchecked Sendable {
    
    init(token: ECKToken, clientId: String) {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Host"] = "login.eveonline.com"
        
        let body = ECKFormURLEncoder.encode([
            (name: "grant_type", value: "refresh_token"),
            (name: "refresh_token", value: token.refreshToken),
            (name: "client_id", value: clientId)
        ])
        
        super.init(host: .eveLogin,
                   endpoint: "/v2/oauth/token",
                   requiredScope: nil,
                   requiredCorpRoles: [],
                   headers: headers,
                   method: .post,
                   body: body)
    }
    
}
