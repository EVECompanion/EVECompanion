//
//  ErrorView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI
import EVECompanionKit

struct ErrorView: View {
    
    let error: ECKWebError
    let action: () async -> Void
    
    private var hideRetryText: Bool {
        switch error {
        case .insufficientCorpRole:
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    switch error {
                    case .insufficientCorpRole(requiredRoles: let requiredRoles):
                        Text("Insufficient Roles.")
                            .foregroundStyle(Color.primary)
                        
                        Text("Requires any of these roles: \(requiredRoles.map(\.title).joined(separator: ", "))")
                            .foregroundStyle(Color.secondary)
                    default:
                        Text("Error loading data!")
                            .foregroundStyle(Color.primary)
                    }
                }
                
                if hideRetryText == false {
                    Text("Retry")
                }
            }
        }
        .disabled(hideRetryText)
    }
    
}

#Preview("Insufficient Roles") {
    ErrorView(error: ECKWebError.insufficientCorpRole(requiredRoles: [.Accountant, .Auditor])) {
        return
    }
}

#Preview("Generic") {
    ErrorView(error: ECKWebError.connectionError) {
        return
    }
}
