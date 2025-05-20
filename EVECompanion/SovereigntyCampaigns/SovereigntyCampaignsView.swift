//
//  SovereigntyCampaignsView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 03.07.24.
//

import SwiftUI
import EVECompanionKit

struct SovereigntyCampaignsView: View {
    
    @StateObject var manager: ECKSovereigntyCampaignManager = .init()
    let timer = Timer.publish(every: 1,
                              on: .main,
                              in: .common).autoconnect()
    
    var body: some View {
        Group {
            switch manager.loadingState {
            case .ready,
                 .error:
                if manager.campaigns.isEmpty {
                    Text("No upcoming sovereignty campaigns.")
                } else {
                    List(manager.campaigns) { campaign in
                        SovereigntyCampaignCell(campaign: campaign)
                    }
                    .onReceive(timer, perform: { _ in
                        manager.campaigns.forEach({ $0.objectWillChange.send() })
                    })
                }
                
            case .loading,
                 .reloading:
                ProgressView()
                
            }
        }
        .animation(.spring, value: manager.campaigns)
        .navigationTitle("Sovereignty Campaigns")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

#Preview {
    SovereigntyCampaignsView(manager: .init(isPreview: true))
}
