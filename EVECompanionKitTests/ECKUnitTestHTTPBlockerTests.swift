//
//  ECKUnitTestHTTPBlockerTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 29.10.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKUnitTestHTTPBlockerTests {

    @Test
    func blocksHTTPAndHTTPSRequests() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        ECKUnitTestHTTPBlocker.addToTestConfiguration(configuration)
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        for urlString in ["http://esi.evetech.net/latest/characters/1/", "https://esi.evetech.net/latest/characters/1/"] {
            let url = try #require(URL(string: urlString))

            do {
                _ = try await session.data(from: url)
                #expect(Bool(false), "HTTP requests must be stopped by the unit-test blocker.")
            } catch let error as NSError {
                #expect(error.domain == ECKUnitTestHTTPBlocker.errorDomain)
            }
        }
    }

    @Test
    func leavesNonHTTPRequestsAlone() throws {
        let fileURL = try #require(URL(string: "file:///tmp/eck-unit-test-fixture"))
        let request = URLRequest(url: fileURL)

        #expect(ECKUnitTestHTTPBlocker.canInit(with: request) == false)
    }
}
