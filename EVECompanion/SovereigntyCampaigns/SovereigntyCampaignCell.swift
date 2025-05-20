//
//  SovereigntyCampaignCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 03.07.24.
//

import SwiftUI
import EVECompanionKit

struct SovereigntyCampaignCell: View {
    
    @ObservedObject var campaign: ECKSovereigntyCampaign
    
    var body: some View {
        HStack {
            progressView
                .frame(width: 100, height: 100)
            Spacer()
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Group {
                    switch campaign.eventType {
                    case .tcuDefense:
                        Text("TCU")
                    case .ihubDefense:
                        Text("IHub")
                    case .stationDefense:
                        EmptyView()
                    case .stationFreeport:
                        EmptyView()
                    case .unknown:
                        Text("Unknown event")
                    }
                }
                .font(.title2)
                .fontWeight(.bold)
                
                Spacer()
                    .frame(height: 10)
                
                Text("\(campaign.solarSystem.solarSystemName) (\(campaign.solarSystem.region.name))")
                    .font(.headline)
                
                if let alliance = campaign.defendingAlliance {
                    Text(alliance.name)
                        .fontWeight(.bold)
                }
                
                Spacer()
                    .frame(height: 10)
                
                Text(ECFormatters.dateFormatter(date: campaign.startTime))
                if campaign.startTime > Date() {
                    Text(ECFormatters.remainingTime(remainingTime: campaign.startTime.timeIntervalSinceNow))
                } else {
                    Text("Active")
                        .font(.headline)
                }
            }
        }
        .animation(.spring, value: campaign.startTime)
    }
    
    @ViewBuilder
    var progressView: some View {
        ZStack {
            Circle()
                .stroke(Color.red, lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(campaign.defenderScore ?? 0))
                .stroke(Color.blue, style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: campaign.defenderScore)
            VStack(spacing: 0) {
                if let defendingAllianceId = campaign.defendingAllianceId {
                    ECImage(id: defendingAllianceId,
                            category: .alliance)
                    .frame(width: 50, height: 50)
                }
                if let defenderScore = campaign.defenderScore {
                    Text("**\(Int(defenderScore * 100))%**")
                }
            }
        }
        
    }
}

struct SovereigntyCampaignCell_Preview: PreviewProvider {
    
    static let timer = Timer.publish(every: 1,
                                     on: .main,
                                     in: .common).autoconnect()
    
    static var previews: some View {
        SovereigntyCampaignCell(campaign: .dummy)
            .onReceive(timer, perform: { _ in
                ECKSovereigntyCampaign.dummy.objectWillChange.send()
            })
    }
    
}
