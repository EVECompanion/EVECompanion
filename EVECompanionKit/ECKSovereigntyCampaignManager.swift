//
//  ECKSovereigntyCampaignManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 03.07.24.
//

public import Combine

public class ECKSovereigntyCampaignManager: ObservableObject {
    
    let isPreview: Bool
    
    @Published public var loadingState: ECKLoadingState = .loading
    @Published public var campaigns: [ECKSovereigntyCampaign] = []
    
    private var lastEtag: String?
    
    public init(isPreview: Bool = false) {
        self.isPreview = isPreview
        
        Task {
            await loadCampaigns()
        }
    }
    
    func loadCampaigns() async {
        repeat {
            if isPreview {
                await generatePreviewCampaigns()
            } else {
                await fetchCampaigns()
            }
            
            try? await Task.sleep(for: .seconds(5))
        } while(true)
    }
    
    @MainActor
    private func generatePreviewCampaigns() async {
        guard campaigns.isEmpty == false else {
            campaigns = [
                .init(attackersScore: nil,
                      campaignId: 0,
                      constellation: .init(constellationId: 20000696),
                      defendingAllianceId: 1354830081,
                      defendingAlliance: .init(name: "Goonswarm Federation",
                                               ticker: "CONDI"),
                      defenderScore: 0.6,
                      eventType: .tcuDefense,
                      solarSystem: .init(solarSystemId: 30004759),
                      startTime: Date() + .fromSeconds(seconds: 30)),
                .init(attackersScore: nil,
                      campaignId: 1,
                      constellation: .init(constellationId: 20000696),
                      defendingAllianceId: 1354830081,
                      defendingAlliance: .init(name: "Goonswarm Federation",
                                               ticker: "CONDI"),
                      defenderScore: 0.6,
                      eventType: .ihubDefense,
                      solarSystem: .init(solarSystemId: 30004759),
                      startTime: Date() + .fromSeconds(seconds: 25))
            ]
            loadingState = .ready
            return
        }
        
        campaigns = campaigns.map({ oldCampaign in
            let newDefenderScore: Float
            
            if oldCampaign.id == 0 {
                newDefenderScore = (oldCampaign.defenderScore ?? 0) + 0.05
            } else {
                newDefenderScore = (oldCampaign.defenderScore ?? 0) - 0.05
            }
            
            return .init(attackersScore: nil,
                         campaignId: oldCampaign.id,
                         constellation: oldCampaign.constellation,
                         defendingAllianceId: oldCampaign.defendingAllianceId,
                         defendingAlliance: oldCampaign.defendingAlliance,
                         defenderScore: newDefenderScore,
                         eventType: oldCampaign.eventType,
                         solarSystem: oldCampaign.solarSystem,
                         startTime: oldCampaign.startTime)
        })
        .filter({ ($0.defenderScore ?? 0) > 0 && ($0.defenderScore ?? 0) < 1 })
    }
    
    @MainActor
    private func fetchCampaigns() async {
        let resource = ECKSovereigntyCampaignsResource(etag: lastEtag)
        do {
            let response = try await ECKWebService().loadResource(resource: resource)
            let fetchedCampaigns = response.response.sorted(by: { $0.startTime < $1.startTime })
            self.lastEtag = ((response.headers["Etag"] ?? response.headers["ETag"]) as? String)
            let newCampaigns = fetchedCampaigns.map({ campaign in
                if let existingCampaign = self.campaigns.first(where: { $0.campaignId == campaign.campaignId }) {
                    existingCampaign.attackersScore = campaign.attackersScore
                    existingCampaign.defenderScore = campaign.defenderScore
                    return existingCampaign
                } else {
                    campaign.loadAllianceIfNecessary()
                    return campaign
                }
            })
            self.campaigns = newCampaigns
            self.loadingState = .ready
        } catch {
            logger.error("Error while fetching sovereignty campaigns \(error)")
            if campaigns.isEmpty {
                self.loadingState = .error
            }
        }
    }
    
}
