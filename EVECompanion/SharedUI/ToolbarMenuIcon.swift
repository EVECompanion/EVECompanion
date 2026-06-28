//
//  ToolbarMenuIcon.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import SwiftUI

struct ToolbarMenuIcon: View {

    let systemImage: String
    let activeSystemImage: String
    let isActive: Bool

    var body: some View {
        Image(systemName: isActive ? activeSystemImage : systemImage)
            .imageScale(.large)
            .foregroundStyle(isActive ? Color.accentColor : Color.primary)
            .symbolRenderingMode(.hierarchical)
    }

}
