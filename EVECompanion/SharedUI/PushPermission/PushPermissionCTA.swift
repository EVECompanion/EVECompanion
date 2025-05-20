//
//  PushPermissionCTA.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 04.05.25.
//

import SwiftUI
import EVECompanionKit

struct PushPermissionCTA: View {
    
    @EnvironmentObject var notificationManager: ECKNotificationManager
    @AppStorage(ECKDefaultKeys.didDismissPushCTA.rawValue) var didDismissPushCTA: Bool = false
    
    private var compact: Bool
    
    init(compact: Bool = false) {
        self.compact = compact
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "bell.fill")
                
                Text("Enable Push Notifications?")
                    .font(.title3)
                    .bold()
            }
            
            Spacer()
                .frame(height: 20)
            
            Text("Would you like to receive push notifications about completed skills or warnings about empty skill queues?")
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 20)
            
            Text("You can always change this later in the settings.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                
            buttonView(text: compact ? "Grant Permission" : "Yes", tintColor: .accentColor) {
                Task {
                    try await notificationManager.requestPermission()
                }
            }
            
            if compact == false {
                Spacer()
                    .frame(height: 20)
                
                buttonView(text: "Maybe Later", tintColor: .red) {
                    didDismissPushCTA = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func buttonView(text: String,
                            tintColor: Color,
                            handler: @escaping () -> Void) -> some View {
        Button {
            handler()
        } label: {
            Text(text)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
    }
    
}

#Preview {
    List {
        PushPermissionCTA()
    }
}

#Preview("PushPermissionCTA Compact") {
    List {
        PushPermissionCTA(compact: true)
    }
}
