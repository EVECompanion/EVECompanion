//
//  ECKSolarSystemImageSource.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 27.06.26.
//

import Foundation

public struct ECKSolarSystemImageSource: Equatable, Sendable {

    public let id: Int
    public let category: ECKImageManager.Category

    public init(id: Int, category: ECKImageManager.Category) {
        self.id = id
        self.category = category
    }

}
