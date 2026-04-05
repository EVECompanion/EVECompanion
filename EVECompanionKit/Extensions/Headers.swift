//
//  Headers.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 05.04.26.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    
    var xPages: Int? {
        return Int(self["X-Pages"] ?? self["x-pages"] ?? "")
    }
    
    var etag: String? {
        return self["Etag"] ?? self["ETag"]
    }
    
}
