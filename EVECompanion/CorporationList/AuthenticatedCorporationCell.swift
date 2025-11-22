//
//  AuthenticatedCorporationCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.11.25.
//

import SwiftUI
import EVECompanionKit

struct AuthenticatedCorporationCell: View {
    
    let corporation: ECKAuthenticatedCorporation
    @ObservedObject private var character: ECKCharacter
    
    init(corporation: ECKAuthenticatedCorporation) {
        self.corporation = corporation
        self.character = corporation.authenticatingCharacter
    }
    
    var body: some View {
        switch corporation.authenticatingCharacter.initialDataLoadingState {
        case .ready,
             .reloading:
            normalView
        case .loading:
            ProgressView()
        case .error:
            // TODO
            Text("Error")
        }
    }
    
    @MainActor
    private var normalView: some View {
        VStack(alignment: .leading) {
            if let corpId = corporation.corpId,
               let corpData = corporation.publicCorpInfo {
                HStack {
                    ECImage(id: corpId,
                            category: .corporation)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    Text(corpData.name)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.title2)
                }
            }
            
            if let allianceId = corporation.allianceId,
               let allianceData = corporation.publicAllianceInfo {
                HStack {
                    ECImage(id: allianceId,
                            category: .alliance)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    Text(allianceData.name)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.title2)
                }
            }
            
            Spacer()
                .frame(height: 20)
            
            Text("Via Character")
            
            HStack {
                ECImage(id: character.id,
                        category: .character)
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                
                Text(character.name)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
}

#Preview {
    List {
        AuthenticatedCorporationCell(corporation: .dummy)
    }
}
