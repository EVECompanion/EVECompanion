//
//  JumpClonesView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.06.24.
//

import SwiftUI
import EVECompanionKit

struct JumpClonesView: View {
    
    @StateObject var jumpClonesManager: ECKJumpClonesManager
    
    var body: some View {
        Group {
            switch jumpClonesManager.loadingState {
            case .ready,
                 .reloading:
                List(jumpClonesManager.jumpClones?.jumpClones ?? []) { jumpClone in
                    JumpCloneCell(jumpClone: jumpClone)
                }
                .refreshable {
                    await jumpClonesManager.loadJumpClones()
                }
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await jumpClonesManager.loadJumpClones()
                }
                
            }
        }
        .navigationTitle("Jump Clones")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if (jumpClonesManager.jumpClones?.jumpClones ?? []).isEmpty && jumpClonesManager.loadingState == .ready {
                ContentEmptyView(image: Image("Neocom/JumpClones"),
                                 title: "No Jump Clones",
                                 subtitle: "New jump clones will appear here")
            }
        }
    }
    
}

#Preview {
    NavigationView {
        JumpClonesView(jumpClonesManager: .init(character: .dummy,
                                                isPreview: true))
    }
}
