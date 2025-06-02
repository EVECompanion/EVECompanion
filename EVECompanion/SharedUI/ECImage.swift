//
//  ECImage.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 26.05.24.
//

import SwiftUI
import Kingfisher
import EVECompanionKit

struct ECImage: View {
    
    let id: Int
    let category: ECKImageManager.Category
    let isBPC: Bool?
    @State var url: URL?
    @State var isLoading: Bool = true
    let size: CGSize?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let url = url {
                if let size {
                    KFImage(url)
                        .setProcessor(ResizingImageProcessor(referenceSize: size))
                        .resizable()
                } else {
                    KFImage(url)
                        .resizable()
                }
            } else {
                Image("Icons/unknownImage")
                    .resizable()
            }
        }.onAppear(perform: {
            if url == nil {
                Task { @MainActor in
                    self.url = await ECKImageManager().loadURL(id: id,
                                                               category: category,
                                                               isBPC: isBPC)
                    self.isLoading = false
                }
            }
        })
    }
    
    init(id: Int, category: ECKImageManager.Category, isBPC: Bool? = nil, size: CGSize? = nil) {
        self.id = id
        self.category = category
        self.isBPC = isBPC
        self.size = size
    }
    
}
