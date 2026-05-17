//
//  MailCreateView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.24.
//

import SwiftUI
import EVECompanionKit

struct MailCreateView: View {
    
    private let character: ECKCharacter
    @Environment(\.dismiss) private var dismiss
    @State private var recipients: [ECKMailRecipient]
    @State private var resolvedRecipients: [ECKMailRecipientSearchResult] = []
    @State private var isRecipientSearchPresented: Bool = false
    @State private var subject: String
    @State private var mailBody: String = ""
    @State private var isSending: Bool = false
    @State private var sendError: ECKWebError?
    @State private var hasResolvedInitialRecipients: Bool = false
    
    private var canSend: Bool {
        recipients.isEmpty == false &&
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        mailBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        isSending == false
    }
    
    init(character: ECKCharacter,
         recipients: [ECKMailRecipient],
         subject: String = "") {
        self.character = character
        self._recipients = State(initialValue: recipients)
        self._subject = State(initialValue: subject)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipients") {
                    if resolvedRecipients.isEmpty {
                        Button {
                            isRecipientSearchPresented = true
                        } label: {
                            HStack {
                                Text("Add Recipients")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } else {
                        ForEach(resolvedRecipients) { recipient in
                            HStack(spacing: 12) {
                                MailRecipientIconView(recipient: recipient)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipient.name)
                                    Text(recipient.recipientType.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    removeRecipient(recipient)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button {
                            isRecipientSearchPresented = true
                        } label: {
                            Label("Add Recipients", systemImage: "plus")
                        }
                    }
                }
                
                Section("Content") {
                    TextField("Subject", text: $subject)
                    TextEditor(text: $mailBody)
                        .frame(minHeight: 220)
                }
                
                if let sendError {
                    Section {
                        Text(sendErrorMessage(for: sendError))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Mail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isSending {
                        ProgressView()
                    } else {
                        Button("Send") {
                            sendMail()
                        }
                        .disabled(canSend == false)
                    }
                }
            }
        }
        .task {
            await resolveInitialRecipientsIfNeeded()
        }
        .sheet(isPresented: $isRecipientSearchPresented) {
            MailRecipientSearchView(character: character,
                                    selectedRecipients: resolvedRecipients) { recipient in
                addRecipient(recipient)
            }
        }
    }
    
    private func addRecipient(_ recipient: ECKMailRecipientSearchResult) {
        guard recipients.contains(recipient.recipient) == false else {
            return
        }
        
        recipients.append(recipient.recipient)
        resolvedRecipients.append(recipient)
    }
    
    private func removeRecipient(_ recipient: ECKMailRecipientSearchResult) {
        recipients.removeAll(where: { $0 == recipient.recipient })
        resolvedRecipients.removeAll(where: { $0 == recipient })
    }
    
    private func resolveInitialRecipientsIfNeeded() async {
        guard hasResolvedInitialRecipients == false else {
            return
        }
        
        hasResolvedInitialRecipients = true
        
        guard recipients.isEmpty == false else {
            resolvedRecipients = []
            return
        }
        
        do {
            resolvedRecipients = try await character.resolveMailRecipients(recipients)
        } catch {
            resolvedRecipients = recipients.map({
                ECKMailRecipientSearchResult(recipient: $0,
                                             name: "Recipient \($0.recipientId)")
            })
        }
    }
    
    private func sendMail() {
        sendError = nil
        isSending = true
        
        Task { @MainActor in
            defer {
                isSending = false
            }
            
            do {
                try await character.sendMail(subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                                             body: mailBody.trimmingCharacters(in: .whitespacesAndNewlines),
                                             recipients: recipients)
                dismiss()
            } catch let error as ECKWebError {
                sendError = error
            } catch {
                sendError = .unknownError
            }
        }
    }
    
    private func sendErrorMessage(for error: ECKWebError) -> String {
        switch error {
        case .insufficientScopes:
            return "This character is missing the mail send scope."
        case .connectionError:
            return "Could not reach ESI."
        default:
            return "The mail could not be sent."
        }
    }
}


