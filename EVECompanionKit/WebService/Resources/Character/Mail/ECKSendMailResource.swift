//
//  ECKSendMailResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKSendMailResource: ECKWebResource<Int>, @unchecked Sendable {
    
    private struct SendMailRequest: Encodable {
        let subject: String
        let body: String
        let recipients: [ECKMailRecipient]
    }
    
    init(token: ECKToken, subject: String, body: String, recipients: [ECKMailRecipient]) {
        super.init(host: .esi,
                   endpoint: "/characters/\(token.characterId)/mail/",
                   token: token,
                   requiredScope: .sendMail,
                   requiredCorpRoles: [],
                   headers: ["X-Compatibility-Date": "2026-05-17"],
                   method: .post,
                   body: SendMailRequest(subject: subject,
                                         body: body,
                                         recipients: recipients))
    }
    
}
