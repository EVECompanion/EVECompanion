//
//  ServerStatusView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 24.05.25.
//

import SwiftUI
import EVECompanionKit

struct ServerStatusView: View {
    
    @StateObject private var serverStatusManager: ECKServerStatusManager = .init()
    @State private var timelineStartDate: Date = .init()
    
    var body: some View {
        statusView
            .animation(.spring, value: serverStatusManager.status?.players)
            .animation(.spring, value: serverStatusManager.loadingState)
        
        serverTimeView
    }
    
    @ViewBuilder
    private var statusView: some View {
        if let status = serverStatusManager.status {
            Label {
                VStack(alignment: .leading) {
                    Text(ECFormatters.playerCount(status.players))
                    Text("Players Online")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "person.3")
                    .foregroundStyle(Color.green)
            }
        } else if serverStatusManager.loadingState == .error {
            Label {
                Text("Server Status Unknown")
            } icon: {
                Image(systemName: "person.3")
                    .foregroundStyle(.red)
            }
        }
    }
    
    @ViewBuilder
    private var serverTimeView: some View {
        TimelineView(.periodic(from: timelineStartDate, by: 1.0)) { context in
            Label {
                VStack(alignment: .leading) {
                    Text(ECFormatters.serverTime(context.date))
                    Text("EVE Time")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "clock")
            }
            .foregroundStyle(.primary)
        }
    }
    
}

#Preview {
    List {
        ServerStatusView()
    }
}
