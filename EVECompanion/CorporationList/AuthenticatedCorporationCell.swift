//
//  AuthenticatedCorporationCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.11.25.
//

import SwiftUI
import EVECompanionKit

struct AuthenticatedCorporationCell: View {
    
    @ObservedObject private var corporation: ECKAuthenticatedCorporation
    private let allowsNavigation: Bool
    
    init(corporation: ECKAuthenticatedCorporation, allowsNavigation: Bool) {
        self.corporation = corporation
        self.allowsNavigation = allowsNavigation
    }
    
    var body: some View {
        if corporation.authenticatingCharacter.hasValidToken
            && allowsNavigation
            && isShowingError == false {
            NavigationLink(value: AppScreen.corporationDetail(corporation)) {
                contentView
            }
        } else {
            contentView
        }
    }
    
    @MainActor
    private var contentView: some View {
        VStack(alignment: .leading) {
            corporationHeaderView
            
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
            
            characterView
            
            statusView
        }
    }
    
    @ViewBuilder
    private var corporationHeaderView: some View {
        HStack {
            if let corpId = corporation.corpId {
                ECImage(id: corpId,
                        category: .corporation)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            }
            
            Text(corporation.publicCorpInfo?.name ?? "Unknown Corporation")
                .fixedSize(horizontal: false, vertical: true)
                .font(.title2)
        }
    }
    
    @ViewBuilder
    private var characterView: some View {
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
    
    @ViewBuilder
    private var statusView: some View {
        switch corporation.authenticatingCharacter.initialDataLoadingState {
        case .ready,
             .reloading:
            EmptyView()
            
        case .loading:
            ProgressView()
            
        case .error(let error):
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                
                ErrorView(error: error) {
                    await corporation.loadInitialData()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            }
            .onTapGesture {
                Task {
                    await corporation.loadInitialData()
                }
            }
        }
    }
    
    private var isShowingError: Bool {
        switch corporation.authenticatingCharacter.initialDataLoadingState {
        case .error:
            return true
        default:
            return false
        }
    }
    
}

#Preview {
    List {
        AuthenticatedCorporationCell(corporation: .dummy, allowsNavigation: false)
    }
}
