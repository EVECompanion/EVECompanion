//
//  MailCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 18.05.24.
//

import SwiftUI
import EVECompanionKit
import Kingfisher

struct MailCell: View {
    
    @ObservedObject var mail: ECKMail
    
    var body: some View {
        HStack {
            
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .opacity(mail.isRead == false ? 1 : 0.0)
            
            if let sender = mail.from {
                ECImage(id: sender,
                        category: .character)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(mail.subject ?? "")
                if let date = mail.timestamp {
                    Text(ECFormatters.dateFormatter(date: date))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .foregroundStyle(mail.isRead ? .secondary : .primary)
    }
    
}

#Preview {
    List {
        Section("Inbox") {
            MailCell(mail: .dummyUnread)
            MailCell(mail: .dummyRead)
            MailCell(mail: .dummyUnreadLong)
        }
    }
}
