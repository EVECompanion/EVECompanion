//
//  ECKPagination.swift
//  EVECompanionKit
//
//  Created by Codex on 04.04.26.
//

import Foundation

public final class ECKPagination: @unchecked Sendable {
    
    public private(set) var totalPages: Int?
    public private(set) var lastLoadedPage: Int
    public private(set) var isLoading = false
    
    public var hasNextPage: Bool {
        guard let totalPages else {
            return true
        }
        
        return lastLoadedPage < totalPages
    }
    
    public init(totalPages: Int? = nil, lastLoadedPage: Int = 0) {
        self.totalPages = totalPages
        self.lastLoadedPage = lastLoadedPage
    }
    
    public func reset() {
        totalPages = nil
        lastLoadedPage = 0
        isLoading = false
    }
    
    @discardableResult
    public func next() -> Int {
        lastLoadedPage += 1
        return lastLoadedPage
    }
    
    public func setTotalPages(headers: [String: String]) {
        if let totalPages = headers.xPages {
            setTotalPages(totalPages)
        } else {
            setTotalPages(1)
        }
    }
    
    public func setTotalPages(_ totalPages: Int?) {
        self.totalPages = totalPages
    }
    
    public func setIsLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
}
