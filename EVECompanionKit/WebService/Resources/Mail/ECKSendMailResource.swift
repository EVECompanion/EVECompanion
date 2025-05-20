//
//  ECKSendMailResource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 16.05.24.
//

import Foundation

class ECKSendMailResource: ECKWebResource<Int> {
    
    private struct SendMailRequest: Encodable {
        let subject: String
        let body: String
        let recipients: [ECKMailRecipient]
    }
    
    init(token: ECKToken, subject: String, body: String, recipients: [ECKMailRecipient]) {
        super.init(host: .esi,
                   endpoint: "/v1/characters/\(token.characterId)mail/",
                   token: token,
                   method: .post,
                   body: SendMailRequest(subject: subject,
                                         body: body,
                                         recipients: recipients))
    }
    
}
