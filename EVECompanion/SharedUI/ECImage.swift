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
    @State var imageSource: Source?
    @State var isLoading: Bool = true
    let size: CGSize?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let imageSource = imageSource {
                if let size {
                    KFImage(source: imageSource)
                        .setProcessor(ResizingImageProcessor(referenceSize: size))
                        .resizable()
                } else {
                    KFImage(source: imageSource)
                        .resizable()
                }
            } else {
                Image("Icons/unknownImage")
                    .resizable()
            }
        }.onAppear(perform: {
            if imageSource == nil {
                Task { @MainActor in
                    if let url = await ECKImageManager().loadURL(id: id,
                                                                 category: category,
                                                                 isBPC: isBPC) {
                        self.imageSource = .network(url)
                    }
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
