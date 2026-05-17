//
//  MailRecipientSearchView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 17.05.26.
//

import SwiftUI
import EVECompanionKit

struct MailRecipientSearchView: View {
    
    private static let searchDebounceNanoseconds: UInt64 = 400 * NSEC_PER_MSEC
    
    private let character: ECKCharacter
    private let selectedRecipients: [ECKMailRecipientSearchResult]
    private let onSelect: (ECKMailRecipientSearchResult) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var recipientSearchText: String = ""
    @State private var recipientSearchResults: [ECKMailRecipientSearchResult] = []
    @State private var mailingListRecipients: [ECKMailRecipientSearchResult] = []
    @State private var recipientSearchState: ECKLoadingState = .ready
    
    init(character: ECKCharacter, selectedRecipients: [ECKMailRecipientSearchResult], onSelect: @escaping (ECKMailRecipientSearchResult) -> Void) {
        self.character = character
        self.selectedRecipients = selectedRecipients
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationStack {
            searchableRecipientList
                .navigationTitle("Add Receiver")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            if #available(iOS 18.0, *) {
                isSearchFocused = true
            }
        }
        .task {
            if #available(iOS 18.0, *) {
                isSearchFocused = true
            }
            await loadMailingLists()
        }
        .task(id: recipientSearchText) {
            await searchRecipients()
        }
    }
    
    @ViewBuilder
    private var searchableRecipientList: some View {
        if #available(iOS 18.0, *) {
            recipientList
                .searchFocused($isSearchFocused)
        } else {
            recipientList
        }
    }
    
    private var recipientList: some View {
        List {
            switch recipientSearchState {
            case .loading:
                ProgressView()
                
            case .error:
                Text("Could not load recipients.")
                    .foregroundStyle(.red)
                
            case .ready,
                 .reloading:
                if recipientSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ForEach(mailingListRecipients) { recipient in
                        Button {
                            onSelect(recipient)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                MailRecipientIconView(recipient: recipient)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipient.name)
                                        .foregroundStyle(.primary)
                                    Text(recipient.recipientType.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } else if recipientSearchText.trimmingCharacters(in: .whitespacesAndNewlines).count < ECKCharacter.mailRecipientSearchMinimumLength {
                    Text("Enter at least \(ECKCharacter.mailRecipientSearchMinimumLength) characters.")
                        .foregroundStyle(.secondary)
                } else if recipientSearchResults.isEmpty {
                    Text("No recipients found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recipientSearchResults) { recipient in
                        Button {
                            onSelect(recipient)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                MailRecipientIconView(recipient: recipient)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipient.name)
                                        .foregroundStyle(.primary)
                                    Text(recipient.recipientType.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $recipientSearchText, prompt: "Search recipients")
    }
    
    private func loadMailingLists() async {
        recipientSearchState = .loading
        
        do {
            mailingListRecipients = try await character.loadMailingListRecipients()
            recipientSearchState = .ready
        } catch {
            mailingListRecipients = []
            recipientSearchState = .error(error)
        }
    }
    
    private func searchRecipients() async {
        let trimmedText = recipientSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            recipientSearchResults = []
            recipientSearchState = .ready
            return
        }
        
        guard trimmedText.count >= ECKCharacter.mailRecipientSearchMinimumLength else {
            recipientSearchResults = []
            recipientSearchState = .ready
            return
        }
        
        recipientSearchState = .loading
        
        do {
            try? await Task.sleep(nanoseconds: Self.searchDebounceNanoseconds)
            guard Task.isCancelled == false else {
                return
            }
            
            let recipients = try await character.searchMailRecipients(trimmedText)
            guard Task.isCancelled == false else {
                return
            }
            
            recipientSearchResults = recipients.filter({ selectedRecipients.contains($0) == false })
            recipientSearchState = .ready
        } catch {
            guard Task.isCancelled == false else {
                return
            }
            
            recipientSearchResults = []
            recipientSearchState = .error(error)
        }
    }
}
