//
//  ECKCharacter+Mail.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 18.05.24.
//

import Foundation

extension ECKCharacter {
    
    public static let mailRecipientSearchMinimumLength: Int = 3
    
    @MainActor
    public var unreadMailCount: Int? {
        guard let mailbox else {
            return nil
        }
        
        return mailbox.reduce(0) { partialResult, mail in
            if mail.isRead {
                return partialResult
            } else {
                return partialResult + 1
            }
        }
    }
    
    @MainActor
    public var inbox: [ECKMail]? {
        guard let mailbox else {
            return nil
        }
        
        return mailbox.filter({ $0.from != self.id })
    }
    
    @MainActor 
    public var outbox: [ECKMail]? {
        guard let mailbox else {
            return nil
        }
        
        return mailbox.filter({ $0.from == self.id })
    }
    
    @MainActor
    public func deleteMail(_ mail: ECKMail) {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            self.mailbox = mailbox?.filter({ $0.id != mail.id })
            return
        }
        
        guard let mailId = mail.mailId else {
            return
        }
        
        Task { @MainActor in
            let originalMailbox = mailbox
            self.mailbox = mailbox?.filter({ $0.id != mail.id })
            let resource = ECKDeleteMailResource(token: token, mailId: mailId)
            
            do {
                _ = try await ECKWebService().loadResource(resource: resource)
            } catch {
                logger.error("Error deleting mail: \(error)")
                self.mailbox = originalMailbox
            }
        }
    }
    
    @MainActor
    public func toggleMailReadStatus(_ mail: ECKMail) {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            mail.isRead.toggle()
            return
        }
        
        guard let mailId = mail.mailId else {
            return
        }
        
        let originalIsReadStatus = mail.isRead
        
        Task { @MainActor in
            mail.isRead.toggle()
            let resource = ECKUpdateMailResource(token: token, mailId: mailId,
                                                 read: originalIsReadStatus == false)
            
            do {
                _ = try await ECKWebService().loadResource(resource: resource)
            } catch {
                logger.error("Error updating mail: \(error)")
                mail.isRead = originalIsReadStatus
            }
        }
    }
    
    @MainActor
    public func sendMail(subject: String,
                         body: String,
                         recipients: [ECKMailRecipient]) async throws(ECKWebError) {
        guard UserDefaults.standard.isDemoModeEnabled == false else {
            let localMail = ECKMail.sentMail(from: id,
                                             mailId: nil,
                                             recipients: recipients,
                                             subject: subject,
                                             body: body,
                                             token: token,
                                             timestamp: Date())
            self.mailbox = [localMail] + (mailbox ?? [])
            return
        }
        
        let resource = ECKSendMailResource(token: token,
                                           subject: subject,
                                           body: body,
                                           recipients: recipients)
        let sentMailId = try await ECKWebService().loadResource(resource: resource).response
        let localMail = ECKMail.sentMail(from: id,
                                         mailId: sentMailId,
                                         recipients: recipients,
                                         subject: subject,
                                         body: body,
                                         token: token,
                                         timestamp: Date())
        self.mailbox = [localMail] + (mailbox ?? [])
    }
    
    @MainActor
    public func searchMailRecipients(_ text: String) async throws(ECKWebError) -> [ECKMailRecipientSearchResult] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= Self.mailRecipientSearchMinimumLength else {
            return []
        }
        
        return try await loadSearchRecipients(trimmedText)
    }
    
    @MainActor
    public func loadMailingListRecipients() async throws(ECKWebError) -> [ECKMailRecipientSearchResult] {
        let mailingLists = try await ECKMailingListManager.shared.get(token: token)
        return mailingLists.map({
            let recipient = ECKMailRecipient(recipientId: $0.mailingListId,
                                             recipientType: .mailingList)
            return ECKMailRecipientSearchResult(recipient: recipient,
                                                name: $0.name)
        })
    }
    
    @MainActor
    public func resolveMailRecipients(_ recipients: [ECKMailRecipient]) async throws(ECKWebError) -> [ECKMailRecipientSearchResult] {
        guard recipients.isEmpty == false else {
            return []
        }
        
        var resolvedRecipients = [RecipientKey: ECKMailRecipientSearchResult]()
        let nonMailingListRecipients = recipients.filter({ $0.recipientType != .mailingList })
        
        if nonMailingListRecipients.isEmpty == false {
            let response = try await ECKWebService().loadResource(resource: ECKUniverseNamesResource(ids: nonMailingListRecipients.map(\.recipientId))).response
            for entry in response {
                guard let recipientType = ECKMailRecipient.ECKRecipientType(searchCategory: entry.category) else {
                    continue
                }
                
                let recipient = ECKMailRecipient(recipientId: entry.id,
                                                 recipientType: recipientType)
                resolvedRecipients[.init(recipient: recipient)] = .init(recipient: recipient,
                                                                        name: entry.name)
            }
        }
        
        if recipients.contains(where: { $0.recipientType == .mailingList }) {
            let mailingLists = try await ECKMailingListManager.shared.get(token: token)
            for mailingList in mailingLists {
                let recipient = ECKMailRecipient(recipientId: mailingList.mailingListId,
                                                 recipientType: .mailingList)
                resolvedRecipients[.init(recipient: recipient)] = .init(recipient: recipient,
                                                                        name: mailingList.name)
            }
        }
        
        return recipients.compactMap { recipient in
            resolvedRecipients[.init(recipient: recipient)] ?? .init(recipient: recipient,
                                                                     name: "Recipient \(recipient.recipientId)")
        }
    }
    
    @MainActor
    private func loadSearchRecipients(_ text: String) async throws(ECKWebError) -> [ECKMailRecipientSearchResult] {
        let response = try await ECKWebService().loadResource(resource: ECKSearchResource(mailRecipientSearchText: text,
                                                                                          token: token)).response
        let recipientCandidates = response.mailRecipients
        guard recipientCandidates.isEmpty == false else {
            return []
        }
        
        let names = try await ECKWebService().loadResource(resource: ECKUniverseNamesResource(ids: recipientCandidates.map(\.recipientId))).response
        let resolvedNameEntries: [(RecipientKey, String)] = names.compactMap { entry in
            guard let recipientType = ECKMailRecipient.ECKRecipientType(searchCategory: entry.category) else {
                return nil
            }
            
            let recipient = ECKMailRecipient(recipientId: entry.id,
                                             recipientType: recipientType)
            return (RecipientKey(recipient: recipient), entry.name)
        }
        let namesByRecipient = Dictionary(uniqueKeysWithValues: resolvedNameEntries)
        
        return recipientCandidates.compactMap { recipient in
            guard let name = namesByRecipient[.init(recipient: recipient)] else {
                return nil
            }
            
            return .init(recipient: recipient,
                         name: name)
        }
    }
    
}

private struct RecipientKey: Hashable {
    let id: Int
    let type: ECKMailRecipient.ECKRecipientType
    
    init(recipient: ECKMailRecipient) {
        self.id = recipient.recipientId
        self.type = recipient.recipientType
    }
}

private extension ECKMailRecipient.ECKRecipientType {
    
    init?(searchCategory: String) {
        switch searchCategory {
        case "alliance":
            self = .alliance
        case "character":
            self = .character
        case "corporation":
            self = .corporation
        case "mailing_list":
            self = .mailingList
        default:
            return nil
        }
    }
}
