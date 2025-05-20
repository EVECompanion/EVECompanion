//
//  Deeplink.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 13.04.25.
//

import Foundation
import EVECompanionKit

enum Deeplink {
    
    case item(ECKItem)
    
    init?(url: URL) {
        guard url.scheme == "evecompanion" else {
            logger.error("Deeplink has scheme \(String(describing: url.scheme)) instead of \"evecompanion\"")
            return nil
        }
        
        guard url.host == "showinfo" else {
            logger.error("URL has unexpected host \(String(describing: url.host))")
            return nil
        }
        
        guard let typeId = Int(url.pathComponents.last ?? "") else {
            logger.error("Path \(url.path()) does not contain a valid typeId")
            return nil
        }
        
        self = .item(ECKItem(typeId: typeId))
    }
    
    var screen: AppScreen {
        switch self {
        case .item(let item):
            return .item(item)
        }
    }
    
}
