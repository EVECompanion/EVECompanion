//
//  ECKTokenStressTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 16.09.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKTokenStressTests {

    /// Helper to generate valid JWT strings containing standard SSO claims
    private func makeJWT(characterId: Int, name: String = "TestPilot", tag: String = "1", exp: Int = 2524608000) -> String {
        let header = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"
        let bodyObj: [String: Any] = [
            "scp": [],
            "sub": "CHARACTER:EVE:\(characterId)",
            "name": name,
            "tag": tag,
            "exp": exp
        ]
        // swiftlint:disable:next force_try
        let bodyData = try! JSONSerialization.data(withJSONObject: bodyObj)
        let bodyBase64 = bodyData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(header).\(bodyBase64).sig"
    }

    /// Create a valid dummy ECKToken with custom characterId, access token, and refresh token
    private func makeTestToken(
        characterId: Int = 10001,
        characterName: String = "TestPilot",
        accessToken: String? = nil,
        refreshToken: String = "ref_token_1",
        isValid: Bool = true,
        target: ECKAuthenticationTarget = .character,
        exp: Int = 2524608000
    ) throws -> ECKToken {
        let jwt = accessToken ?? makeJWT(characterId: characterId, name: characterName, exp: exp)

        let jsonDict: [String: Any] = [
            "access_token": jwt,
            "refresh_token": refreshToken,
            "isValid": isValid,
            "tokenTarget": target.rawValue
        ]
        let data = try JSONSerialization.data(withJSONObject: jsonDict)
        let token = try JSONDecoder().decode(ECKToken.self, from: data)
        return token
    }

    // MARK: - 1. Keychain Invalidation & Preferred Token Resolution Tests
    // (Tests Bug #4 & Bug #3 resolution in Keychain: Stale invalidations do not overwrite valid tokens)

    @Test
    func testKeychainIgnoresStaleTokenInvalidationWhenNewerTokenExists() async throws {
        let characterId = 60001

        // 1. Store initial valid token (ref_v1)
        let tokenV1 = try makeTestToken(characterId: characterId, refreshToken: "ref_v1", isValid: true)
        await ECKKeychain.add(token: tokenV1)

        // 2. Store updated valid token (ref_v2) representing successful refresh
        let jwtV2 = makeJWT(characterId: characterId, tag: "v2", exp: 2524694400)
        let tokenV2 = try makeTestToken(characterId: characterId, accessToken: jwtV2, refreshToken: "ref_v2", isValid: true)
        await ECKKeychain.add(token: tokenV2)

        // Verify Keychain has tokenV2
        let tokensAfterV2 = await ECKKeychain.getTokens(target: .character)
        let savedV2 = try #require(tokensAfterV2.first(where: { $0.characterId == characterId }))
        #expect(savedV2.refreshToken == "ref_v2")
        #expect(savedV2.isValid == true)

        // 3. Simulate a stale request returning 400 invalid_grant for ref_v1, creating a token with isValid = false
        let staleInvalidToken = try makeTestToken(characterId: characterId, refreshToken: "ref_v1", isValid: false)
        await ECKKeychain.add(token: staleInvalidToken)

        // 4. VERIFY: Keychain MUST preserve tokenV2 (isValid == true, ref_v2) and NOT overwrite with stale invalid token!
        let tokensAfterStaleAdd = await ECKKeychain.getTokens(target: .character)
        let finalToken = try #require(tokensAfterStaleAdd.first(where: { $0.characterId == characterId }))
        #expect(finalToken.isValid == true)
        #expect(finalToken.refreshToken == "ref_v2")

        // Teardown
        await ECKKeychain.remove(token: finalToken)
    }

    @Test
    func testKeychainPersistsLegitimateTokenInvalidation() async throws {
        let characterId = 60002

        // Store initial valid token
        let tokenV1 = try makeTestToken(characterId: characterId, refreshToken: "ref_v1", isValid: true)
        await ECKKeychain.add(token: tokenV1)

        // Simulate genuine invalidation (e.g. user logged out or revoked access on ESI)
        let invalidatedToken = try makeTestToken(characterId: characterId, refreshToken: "ref_v1", isValid: false)
        await ECKKeychain.add(token: invalidatedToken)

        // VERIFY: Keychain reflects isValid == false for this character
        let tokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(tokens.first(where: { $0.characterId == characterId }))
        #expect(savedToken.isValid == false)

        // Teardown
        await ECKKeychain.remove(token: savedToken)
    }

    @Test
    func testMatchingRefreshTokenInvalidationWinsOverLaterAccessTokenExpiry() async throws {
        let characterId = 60003

        let storedToken = try makeTestToken(
            characterId: characterId,
            refreshToken: "ref_same",
            isValid: true,
            exp: 2524694400
        )
        await ECKKeychain.add(token: storedToken)

        // This instance carries an older access token but invalidates the same
        // refresh credential, so the keychain must persist the invalidation.
        let invalidatedToken = try makeTestToken(
            characterId: characterId,
            refreshToken: "ref_same",
            isValid: false,
            exp: 2524608000
        )
        await ECKKeychain.add(token: invalidatedToken)

        let tokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(tokens.first(where: { $0.characterId == characterId }))
        #expect(savedToken.isValid == false)
        #expect(savedToken.refreshToken == "ref_same")

        await ECKKeychain.remove(token: savedToken)
    }

    // MARK: - 2. Stale 400 invalid_grant Response Handling Tests
    // (Tests Bug #3: 400 invalid_grant on stale token syncs from Keychain instead of invalidating character)

    @Test
    func testStaleInvalidGrantDecisionSyncsFromKeychain() async throws {
        let characterId = 70001

        // 1. Keychain contains fresh valid token (ref_fresh) from another concurrent refresh task
        let freshKeychainToken = try makeTestToken(characterId: characterId, refreshToken: "ref_fresh", isValid: true)
        await ECKKeychain.add(token: freshKeychainToken)

        // 2. A stale token instance (ref_stale) receives a 400 invalid_grant error from ESI
        let staleTokenInstance = try makeTestToken(characterId: characterId, refreshToken: "ref_stale", isValid: true)

        // Exercise the same decision method used by performTokenRefresh for invalid_grant responses.
        let webService = ECKWebService()
        let didSync = await webService.syncIfNewerTokenExists(for: staleTokenInstance)

        let isStillValid = await staleTokenInstance.isValid
        let updatedRefToken = await staleTokenInstance.refreshToken

        #expect(didSync == true)
        #expect(isStillValid == true)
        #expect(updatedRefToken == "ref_fresh")

        // Teardown
        await ECKKeychain.remove(token: freshKeychainToken)
    }

    // MARK: - 3. ECKWebService refreshToken Coalescing & Control Flow Tests
    // (Tests Bug #1: Missing return statement in refreshToken causing Task 2 to fall through to ESI)

    @Test
    func testWebServiceRefreshTokenCoalescingEarlyReturn() async throws {
        let characterId = 80001
        let account = "\(characterId)-character"

        let tokenB = try makeTestToken(characterId: characterId, refreshToken: "ref_b", isValid: true)

        // Create a long-running mock refresh task for account
        let inFlightTask: Task<Void, any Error> = Task { @ECKTokenActor in
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        await ECKTokenActor.setRefreshTask(inFlightTask, for: account)

        // Store refreshed token in Keychain (simulating Task 1 completing successfully)
        let refreshedToken = try makeTestToken(characterId: characterId, refreshToken: "ref_refreshed", isValid: true)
        await ECKKeychain.add(token: refreshedToken)

        let webService = ECKWebService()

        // Caller B invokes refreshToken(oldToken: tokenB) while inFlightTask is active
        try await webService.refreshToken(oldToken: tokenB)

        // VERIFY: tokenB was synced from Keychain and isValid == true
        let tokenBRef = await tokenB.refreshToken
        let tokenBValid = await tokenB.isValid

        #expect(tokenBRef == "ref_refreshed")
        #expect(tokenBValid == true)

        // Clean up
        await ECKTokenActor.setRefreshTask(nil, for: account)
        await ECKKeychain.remove(token: refreshedToken)
    }

    @Test
    func testCoalescedRefreshFailsWhenSharedTaskDoesNotProduceNewToken() async throws {
        let characterId = 80002
        let account = "\(characterId)-character"
        let expiredToken = try makeTestToken(characterId: characterId, refreshToken: "ref_expired", exp: 1)
        let completedTask = Task<Void, any Error> { @ECKTokenActor in }
        await ECKTokenActor.setRefreshTask(completedTask, for: account)

        var didThrow = false
        do {
            try await ECKWebService().refreshToken(oldToken: expiredToken)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        await ECKTokenActor.setRefreshTask(nil, for: account)
    }

    @Test
    func testCoalescedRefreshFailsWhenTokenIsRemovedWhileWaiting() async throws {
        let characterId = 80003
        let account = "\(characterId)-character"
        let oldToken = try makeTestToken(characterId: characterId, refreshToken: "ref_old")
        let refreshedToken = try makeTestToken(characterId: characterId, refreshToken: "ref_new")
        await ECKKeychain.add(token: refreshedToken)

        await oldToken.prepareForRemoval()
        let completedTask = Task<Void, any Error> { @ECKTokenActor in }
        await ECKTokenActor.setRefreshTask(completedTask, for: account)

        var didThrow = false
        do {
            try await ECKWebService().refreshToken(oldToken: oldToken)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        await ECKTokenActor.setRefreshTask(nil, for: account)
        await ECKKeychain.remove(token: refreshedToken)
    }

    // MARK: - 4. Task Coalescing & Concurrent Refresh Stress Tests
    // (Tests Bug #2: Task coalescing across multiple ECKToken instances for same character)

    @Test
    func testConcurrentRefreshTaskCoalescingForSameAccount() async throws {
        let account = "10001-character"

        // Ensure clean initial state for test account
        await ECKTokenActor.setRefreshTask(nil, for: account)

        let initialTaskCount = await ECKTokenActor.refreshTask(for: account)
        #expect(initialTaskCount == nil)

        // Create a long-running mock refresh task
        let refreshTask: Task<Void, any Error> = Task { @ECKTokenActor in
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        await ECKTokenActor.setRefreshTask(refreshTask, for: account)

        // Launch 50 concurrent caller tasks asking for the refresh task
        await withTaskGroup(of: Task<Void, any Error>?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    return await ECKTokenActor.refreshTask(for: account)
                }
            }

            for await task in group {
                #expect(task != nil)
            }
        }

        // Wait for task to finish and clean up
        _ = try? await refreshTask.value
        await ECKTokenActor.setRefreshTask(nil, for: account)
    }

    @Test
    func testMultiAccountConcurrentRefreshIsolation() async throws {
        let characterIds = [20001, 20002, 20003, 20004, 20005]

        // Clear tasks
        for cid in characterIds {
            await ECKTokenActor.setRefreshTask(nil, for: "\(cid)-character")
        }

        // Launch concurrent refresh task registrations across 5 different characters
        await withTaskGroup(of: Void.self) { group in
            for cid in characterIds {
                let account = "\(cid)-character"
                group.addTask {
                    let task: Task<Void, any Error> = Task { @ECKTokenActor in
                        try await Task.sleep(nanoseconds: 50_000_000)
                    }
                    await ECKTokenActor.setRefreshTask(task, for: account)

                    // Verify task registered specifically for this account
                    let retrievedTask = await ECKTokenActor.refreshTask(for: account)
                    #expect(retrievedTask != nil)
                    
                    _ = try? await task.value
                    await ECKTokenActor.setRefreshTask(nil, for: account)
                }
            }
        }

        // Verify clean teardown for all accounts
        for cid in characterIds {
            let task = await ECKTokenActor.refreshTask(for: "\(cid)-character")
            #expect(task == nil)
        }
    }

    @Test
    func testStaleRefreshTaskCleanupPreservesNewerRegistration() async throws {
        let account = "refresh-cleanup-\(UUID().uuidString)"
        let oldID = UUID()
        let newID = UUID()
        let oldTask = Task<Void, any Error> {
            throw NSError(domain: "old-refresh", code: 1)
        }
        let newTask = Task<Void, any Error> {
            throw NSError(domain: "new-refresh", code: 2)
        }

        await ECKTokenActor.setRefreshTask(oldTask, for: account, id: oldID)
        await ECKTokenActor.setRefreshTask(newTask, for: account, id: newID)

        // A completing old task must not remove the newer account registration.
        await ECKTokenActor.clearRefreshTask(for: account, matching: oldID)
        let maybeRegisteredTask = await ECKTokenActor.refreshTask(for: account)
        let registeredTask = try #require(maybeRegisteredTask)
        do {
            try await registeredTask.value
            #expect(Bool(false))
        } catch let error as NSError {
            #expect(error.domain == "new-refresh")
        }

        // The current registration can still be removed by its own cleanup.
        await ECKTokenActor.clearRefreshTask(for: account, matching: newID)
        let finalTask = await ECKTokenActor.refreshTask(for: account)
        #expect(finalTask == nil)
    }

    // MARK: - 5. In-Memory Token Synchronization Stress Tests

    @Test
    func testTokenSyncFromLatestToken() async throws {
        let jwt1 = makeJWT(characterId: 30001, tag: "v1")
        let jwt2 = makeJWT(characterId: 30001, tag: "v2")
        let tokenA = try makeTestToken(characterId: 30001, accessToken: jwt1, refreshToken: "ref_v1", isValid: true)
        let tokenB = try makeTestToken(characterId: 30001, accessToken: jwt2, refreshToken: "ref_v2", isValid: true)

        await tokenA.sync(from: tokenB)

        let accessTokenA = await tokenA.accessToken
        let refreshTokenA = await tokenA.refreshToken
        let isValidA = await tokenA.isValid

        #expect(accessTokenA == jwt2)
        #expect(refreshTokenA == "ref_v2")
        #expect(isValidA == true)
    }

    @Test
    func testStaleRefreshResponseCannotOverwriteNewerKeychainToken() async throws {
        let characterId = 30002
        let initialAccessToken = makeJWT(characterId: characterId, tag: "initial", exp: 2524608000)
        let initialToken = try makeTestToken(
            characterId: characterId,
            accessToken: initialAccessToken,
            refreshToken: "ref_initial"
        )
        let staleRefreshToken = try makeTestToken(
            characterId: characterId,
            accessToken: initialAccessToken,
            refreshToken: "ref_initial"
        )
        await ECKKeychain.add(token: initialToken)

        let newerAccessToken = makeJWT(characterId: characterId, tag: "newer", exp: 2524694400)
        let newerToken = try makeTestToken(
            characterId: characterId,
            accessToken: newerAccessToken,
            refreshToken: "ref_newer"
        )
        await ECKKeychain.add(token: newerToken)

        let staleResponseAccessToken = makeJWT(characterId: characterId, tag: "stale-response", exp: 2524780800)
        let result = await staleRefreshToken.updateToken(
            accessToken: staleResponseAccessToken,
            refreshToken: "ref_stale-response",
            replacingAccessToken: initialAccessToken,
            refreshToken: "ref_initial"
        )

        let savedTokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(savedTokens.first(where: { $0.characterId == characterId }))
        #expect(result == .superseded)
        #expect(savedToken.accessToken == newerAccessToken)
        #expect(savedToken.refreshToken == "ref_newer")
        let syncedAccessToken = await staleRefreshToken.accessToken
        #expect(syncedAccessToken == newerAccessToken)
        await ECKKeychain.remove(token: savedToken)
    }

    @Test
    func testRefreshResponseUpdatesTokenWhenStartingCredentialIsStillCurrent() async throws {
        let characterId = 30003
        let initialAccessToken = makeJWT(characterId: characterId, tag: "initial", exp: 2524608000)
        let initialToken = try makeTestToken(
            characterId: characterId,
            accessToken: initialAccessToken,
            refreshToken: "ref_initial"
        )
        await ECKKeychain.add(token: initialToken)

        let refreshedAccessToken = makeJWT(characterId: characterId, tag: "refreshed", exp: 2524694400)
        let result = await initialToken.updateToken(
            accessToken: refreshedAccessToken,
            refreshToken: "ref_refreshed",
            replacingAccessToken: initialAccessToken,
            refreshToken: "ref_initial"
        )

        let savedTokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(savedTokens.first(where: { $0.characterId == characterId }))
        #expect(result == .updated)
        #expect(savedToken.accessToken == refreshedAccessToken)
        #expect(savedToken.refreshToken == "ref_refreshed")
        #expect(savedToken.isValid == true)
        await ECKKeychain.remove(token: savedToken)
    }

    @Test
    func testTokenSyncIgnoresRemovedToken() async throws {
        let jwt1 = makeJWT(characterId: 40001, tag: "v1")
        let jwt2 = makeJWT(characterId: 40001, tag: "v2")
        let tokenA = try makeTestToken(characterId: 40001, accessToken: jwt1, refreshToken: "ref_v1", isValid: true)
        let tokenB = try makeTestToken(characterId: 40001, accessToken: jwt2, refreshToken: "ref_v2", isValid: true)

        await tokenA.prepareForRemoval()
        await tokenA.sync(from: tokenB)

        let accessTokenA = tokenA.accessToken
        let refreshTokenA = tokenA.refreshToken

        // Removed token should not be mutated by sync
        #expect(accessTokenA == jwt1)
        #expect(refreshTokenA == "ref_v1")
    }

    // MARK: - 6. Removal Safeguard Tests

    @Test
    func testTokenInvalidationSafeguardsWhenRemoved() async throws {
        let token = try makeTestToken(characterId: 50001, isValid: true)

        await token.prepareForRemoval()
        await token.markAsInvalid()

        let isRemoved = await token.isRemoved
        let isValid = token.isValid

        // Should remain removed and NOT marked invalid when already removed
        #expect(isRemoved == true)
        #expect(isValid == true)
    }
}
