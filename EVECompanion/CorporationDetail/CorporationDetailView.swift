//
//  CorporationDetailView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 29.11.25.
//

import SwiftUI
import EVECompanionKit

struct CorporationDetailView: View {
    
    @ObservedObject private var corporation: ECKAuthenticatedCorporation
    
    init(corporation: ECKAuthenticatedCorporation) {
        self.corporation = corporation
    }
    
    var body: some View {
        List {
            Section {
                if let corpId = corporation.corpId,
                   let corpInfo = corporation.publicCorpInfo {
                    HStack {
                        ECImage(id: corpId,
                                category: .corporation)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        Text(corpInfo.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.title2)
                    }
                }
                
                if let allianceId = corporation.allianceId,
                   let allianceInfo = corporation.publicAllianceInfo {
                    HStack {
                        ECImage(id: allianceId,
                                category: .alliance)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        Text(allianceInfo.name)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.title2)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Via Character")
                    
                    HStack {
                        ECImage(id: corporation.authenticatingCharacter.id,
                                category: .character)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        
                        Text(corporation.authenticatingCharacter.name)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .navigationTitle(corporation.publicCorpInfo?.name ?? "")
    }
    
}

#Preview {
    CoordinatorView(initialScreen: .corporationDetail(.dummy))
}
