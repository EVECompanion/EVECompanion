//
//  PageLoaderView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 04.04.26.
//

import SwiftUI
import Combine
import EVECompanionKit

struct PageLoaderView<PageLoader: ECKPageLoadable, Content: View>: View {
    
    @MainActor
    @ObservedObject var pageLoader: PageLoader
    
    @ViewBuilder let content: (PageLoader.Element) -> Content
    
    @State private var isLoadingNextPage = false
    @State private var loadingError = false
    
    var body: some View {
        Group {
            ForEach(pageLoader.elements) { element in
                content(element)
            }
            
            if pageLoader.hasNextPage {
                if loadingError {
                    HStack {
                        Spacer()
                        RetryButton {
                            await loadNextPage()
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .onAppear {
                        Task {
                            await loadNextPage()
                        }
                    }
                }
            }
        }
    }
    
    @MainActor
    private func loadNextPage() async {
        guard isLoadingNextPage == false else {
            return
        }
        
        isLoadingNextPage = true
        loadingError = false
        
        do {
            try await pageLoader.loadNextPage()
        } catch {
            loadingError = true
        }
        
        isLoadingNextPage = false
    }
    
}

#Preview {
    List {
        PageLoaderView(pageLoader: PreviewPageLoader(mode: .finished)) { item in
            Text(item.title)
        }
    }
}

#Preview("Elements and Spinner") {
    List {
        PageLoaderView(pageLoader: PreviewPageLoader(mode: .loading)) { item in
            Text(item.title)
        }
    }
}

#Preview("Elements and Error State") {
    List {
        PageLoaderView(pageLoader: PreviewPageLoader(mode: .error)) { item in
            Text(item.title)
        }
    }
}

private struct PreviewPageLoaderItem: Identifiable {
    let id = UUID()
    let title: String
}

@MainActor
private final class PreviewPageLoader: ECKPageLoadable {
    
    enum Mode {
        case loading
        case error
        case finished
    }
    
    @Published var elements: [PreviewPageLoaderItem]
    
    @Published var hasNextPage = true
    
    private let mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
        self.elements = (1...10).map {
            .init(title: "Item \($0)")
        }
        self.hasNextPage = mode != .finished
    }
    
    func reload() async {
        elements = (1...10).map {
            .init(title: "Item \($0)")
        }
        hasNextPage = true
    }
    
    func loadNextPage() async throws {
        switch mode {
        case .loading:
            try await Task.sleep(for: .seconds(30))
            
        case .error:
            struct PreviewError: Error {}
            throw PreviewError()
            
        case .finished:
            hasNextPage = false
        }
        
        if mode != .finished {
            hasNextPage = true
        }
    }
    
}
