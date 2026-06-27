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

    private struct LoadRequest: Hashable {
        let id: Int
        let category: ECKImageManager.Category
        let isBPC: Bool?
    }
    
    let id: Int
    let category: ECKImageManager.Category
    let isBPC: Bool?
    @State var imageSource: Source?
    @State var isLoading: Bool = true
    let size: CGSize?

    private var loadRequest: LoadRequest {
        .init(id: id, category: category, isBPC: isBPC)
    }
    
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
        }
        .task(id: loadRequest) {
            isLoading = true
            imageSource = nil

            if let url = await ECKImageManager().loadURL(id: loadRequest.id,
                                                         category: loadRequest.category,
                                                         isBPC: loadRequest.isBPC),
               Task.isCancelled == false {
                imageSource = .network(url)
            }

            if Task.isCancelled == false {
                isLoading = false
            }
        }
    }
    
    init(id: Int, category: ECKImageManager.Category, isBPC: Bool? = nil, size: CGSize? = nil) {
        self.id = id
        self.category = category
        self.isBPC = isBPC
        self.size = size
    }
    
}
