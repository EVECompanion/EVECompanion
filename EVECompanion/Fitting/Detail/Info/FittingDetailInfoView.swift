//
//  FittingDetailInfoView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import SwiftUI
import EVECompanionKit

struct FittingDetailInfoView: View {
    
    @ObservedObject private var fitting: ECKCharacterFitting
    
    init(fitting: ECKCharacterFitting) {
        self.fitting = fitting
    }
    
    var body: some View {
        List {
            
        }
    }
    
}

#Preview {
    FittingDetailInfoView(fitting: .dummyAvatar)
}
