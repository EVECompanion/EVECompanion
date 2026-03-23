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
    @State private var timelineStartDate: Date = .init()
    
    var body: some View {
        Group {
            switch jumpClonesManager.loadingState {
            case .ready,
                 .reloading:
                List {
                    if let nextCloneJumpDate = jumpClonesManager.nextCloneJumpDate, nextCloneJumpDate > Date() {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Next jump clone available in")
                                Text(ECFormatters.remainingTime(remainingTime: nextCloneJumpDate.timeIntervalSinceNow))
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.yellow)
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    ForEach(jumpClonesManager.jumpClones?.jumpClones ?? []) { jumpClone in
                        JumpCloneCell(jumpClone: jumpClone)
                    }
                }
                .refreshable {
                    await jumpClonesManager.loadJumpClones()
                }
                .animation(.spring, value: (jumpClonesManager.nextCloneJumpDate ?? Date()) > Date())
                
            case .loading:
                ProgressView()
                
            case .error:
                RetryButton {
                    await jumpClonesManager.loadJumpClones()
                }
                
            }
        }
        .navigationTitle("Jump Clones")
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
