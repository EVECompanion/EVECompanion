//
//  MailDetailView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 18.05.24.
//

import SwiftUI
import EVECompanionKit

struct MailDetailView: View {
    
    @ObservedObject var mail: ECKMail
    @State var showReplyView: Bool = false
    let character: ECKCharacter
    
    var body: some View {
        ScrollView {
            VStack {
                switch mail.loadingState {
                case .ready,
                     .reloading:
                    AttributedTextView(mail.body ?? "")
                    
                    Spacer()
                    
                case .loading:
                    ProgressView()
                    
                case .error:
                    Spacer()
                    
                    Text("Error loading Mail Content")
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Button(action: {
                        self.fetchMailAndMarkAsRead()
                    }, label: {
                        Text("Retry")
                    })
                    
                    Spacer()
                    
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle(mail.subject ?? "")
        .onAppear(perform: {
            fetchMailAndMarkAsRead()
        })
//        .toolbar(content: {
//            if mail.from != character.id {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button(action: {
//                        showReplyView = true
//                    }, label: {
//                        Image(systemName: "arrowshape.turn.up.left")
//                    })
//                }
//            }
//        })
        .sheet(isPresented: $showReplyView, content: {
            MailCreateView(character: character,
                           recipients: mail.replyRecipient)
        })
    }
    
    func fetchMailAndMarkAsRead() {
        Task { @MainActor in
            await mail.fetchBody()
            
            if mail.loadingState == .ready && mail.isRead == false {
                character.toggleMailReadStatus(mail)
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        MailDetailView(mail: .dummyRead,
                       character: .dummy)
    }
}
