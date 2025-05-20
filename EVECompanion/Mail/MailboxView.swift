//
//  MailboxView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 18.05.24.
//

import SwiftUI
import EVECompanionKit

struct MailboxView: View {
    
    @ObservedObject var character: ECKCharacter
    @State var isInboxExpanded: Bool = true
    @State var isOutboxExpanded: Bool = true
    @State var mailToDelete: ECKMail?
    @State var mailToReply: ECKMail?
    @State var showMailCreateView: Bool = false
    
    var body: some View {
        List {
            Section(content: {
                if isInboxExpanded {
                    ForEach(character.inbox ?? []) { mail in
                        NavigationLink {
                            MailDetailView(mail: mail,
                                           character: character)
                        } label: {
                            MailCell(mail: mail)
                        }
                        .swipeActions(edge: .trailing,
                                      allowsFullSwipe: true) {
                            Button(action: {
                                self.mailToDelete = mail
                            }, label: {
                                Label(
                                    title: { Text("Delete") },
                                    icon: { Image(systemName: "trash") }
                                )
                            })
                            .tint(Color.red)
                        }
                       .swipeActions(edge: .leading,
                                     allowsFullSwipe: true) {
                           Button(action: {
                               character.toggleMailReadStatus(mail)
                           }, label: {
                               if mail.isRead {
                                   Label(
                                     title: { Text("Mark as Unread") },
                                     icon: { Image(systemName: "envelope.badge") }
                                   )
                               } else {
                                   Label(
                                     title: { Text("Mark as Read") },
                                     icon: { Image(systemName: "envelope.open") }
                                   )
                               }
                           })
                           .tint(Color.blue)
                           
//                           Button(action: {
//                               mailToReply = mail
//                               showMailCreateView = true
//                           }, label: {
//                               Label(
//                                 title: { Text("Reply") },
//                                 icon: { Image(systemName: "arrowshape.turn.up.left") }
//                               )
//                           })
//                           .tint(Color.blue)
                       }
                    }
                }
            }, header: {
                MailboxSectionHeaderView(isOn: $isInboxExpanded,
                                         title: "Inbox",
                                         onButtonTitle: "Hide",
                                         offButtonTitle: "Show")
            })
            
            Section(content: {
                if isOutboxExpanded {
                    ForEach(character.outbox ?? []) { mail in
                        NavigationLink {
                            MailDetailView(mail: mail,
                                           character: character)
                        } label: {
                            MailCell(mail: mail)
                        }
                        .swipeActions(edge: .trailing,
                                      allowsFullSwipe: true) {
                            Button(action: {
                                self.mailToDelete = mail
                            }, label: {
                                Label(
                                    title: { Text("Delete") },
                                    icon: { Image(systemName: "trash") }
                                )
                            })
                        }
                    }
                }
            }, header: {
                MailboxSectionHeaderView(isOn: $isOutboxExpanded,
                                         title: "Sent",
                                         onButtonTitle: "Hide",
                                         offButtonTitle: "Show")
            })
        }
        .alert(isPresented: .init(get: {
            return mailToDelete != nil
        }, set: { _ in
            return
        }),
               content: {
            Alert(title: Text("Do you really want to delete this mail?"),
                  primaryButton: .cancel({
                self.mailToDelete = nil
            }),
                  secondaryButton: .destructive(Text("Delete"),
                                                action: {
                guard let mailToDelete else {
                    return
                }
                
                character.deleteMail(mailToDelete)
                self.mailToDelete = nil
            }))
        })
        .animation(.spring, value: character.inbox)
        .animation(.spring, value: character.outbox)
//        .toolbar(content: {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button(action: {
//                    showMailCreateView = true
//                }, label: {
//                    Image(systemName: "square.and.pencil")
//                })
//            }
//        })
        .sheet(isPresented: $showMailCreateView, content: {
            MailCreateView(character: character,
                           recipients: mailToReply?.replyRecipient ?? [])
                .onDisappear(perform: {
                    self.mailToReply = nil
                })
        })
    }
    
}

#Preview {
    NavigationStack {
        MailboxView(character: .dummy)
    }
}
