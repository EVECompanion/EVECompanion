//
//  MailboxSectionHeaderView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 19.05.24.
//

import SwiftUI

struct MailboxSectionHeaderView: View {

    @Binding var isOn: Bool
    let title: String
    let onButtonTitle: String
    let offButtonTitle: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                isOn.toggle()
            }
        }, label: {
            if isOn {
                Text(onButtonTitle)
            } else {
                Text(offButtonTitle)
            }
        })
        .frame(maxWidth: .infinity, alignment: .trailing)
        .overlay(
          Text(title),
          alignment: .leading
        )
    }
}

#Preview {
    MailboxSectionHeaderView(isOn: .constant(true),
                             title: "Inbox",
                             onButtonTitle: "Hide",
                             offButtonTitle: "Show")
}
