//
//  MailRecipientIconView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import SwiftUI
import EVECompanionKit

struct MailRecipientIconView: View {
    
    let recipient: ECKMailRecipientSearchResult
    
    var body: some View {
        switch recipient.recipientType {
        case .alliance:
            ECImage(id: recipient.recipient.recipientId,
                    category: .alliance)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        case .character:
            ECImage(id: recipient.recipient.recipientId,
                    category: .character)
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            
        case .corporation:
            ECImage(id: recipient.recipient.recipientId,
                    category: .corporation)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        case .mailingList:
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview("Alliance") {
    MailRecipientIconView(recipient: .init(recipient: .init(recipientId: 498125261, recipientType: .alliance), name: "Test Alliance Please Ignore"))
}

#Preview("Corporation") {
    MailRecipientIconView(recipient: .init(recipient: .init(recipientId: 1018389948, recipientType: .corporation), name: "Dreddit"))
}

#Preview("Character") {
    MailRecipientIconView(recipient: .init(recipient: .init(recipientId: 2123087197, recipientType: .character), name: "EVECompanion"))
}

#Preview("Mailing List") {
    MailRecipientIconView(recipient: .init(recipient: .init(recipientId: 0, recipientType: .mailingList), name: "Awesome Mailing List"))
}
