//
//  ECKCharacter+Mail.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 18.05.24.
//

import Foundation

extension ECKCharacter {
    
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
    
}
