//
//  ContentEmptyView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 15.08.24.
//

import SwiftUI

struct ContentEmptyView: View {
    
    let image: Image
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack {
            image
                .font(.system(size: 50))
                .foregroundStyle(Color.secondary)
            
            Spacer()
                .frame(height: 10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
    }
    
}

#Preview {
    ContentEmptyView(image: Image(systemName: "tray.fill"),
                     title: "No Mail",
                     subtitle: "New mails you receive will appear here.")
}
