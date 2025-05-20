//
//  RetryButton.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 08.06.24.
//

import SwiftUI

struct RetryButton: View {
    
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            VStack(spacing: 10) {
                Text("Error loading data!")
                    .foregroundStyle(Color.primary)
                
                Text("Retry")
            }
        }
    }
    
}

#Preview {
    RetryButton {
        return
    }
}
