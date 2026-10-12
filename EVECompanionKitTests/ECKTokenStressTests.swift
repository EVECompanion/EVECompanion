//
//  ECKTokenStressTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 16.09.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

private actor ECKTokenRefreshTestGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var isPaused = false

    func pause() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            isPaused = true
            startedContinuation?.resume()
            startedContinuation = nil
        }
    }

    func waitUntilPaused() async {
        guard isPaused == false else { return }
        await withCheckedContinuation { continuation in
            startedContinuation = continuation
        }
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}

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

    @Test
    func testSuccessfulRefreshReplacesRotatedCredentialEvenWithEarlierExpiry() async throws {
        let characterId = 60004
        let storedAccessToken = makeJWT(characterId: characterId, tag: "stored", exp: 2524694400)
        let token = try makeTestToken(
            characterId: characterId,
            accessToken: storedAccessToken,
            refreshToken: "ref_before_refresh"
        )
        await ECKKeychain.add(token: token)

        let refreshedAccessToken = makeJWT(characterId: characterId, tag: "refreshed", exp: 2524608000)
        let updateResult = await token.updateToken(
            accessToken: refreshedAccessToken,
            refreshToken: "ref_after_refresh",
            replacingAccessToken: storedAccessToken,
            refreshToken: "ref_before_refresh"
        )
        let tokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(tokens.first(where: { $0.characterId == characterId }))

        #expect(updateResult == .updated)
        #expect(savedToken.accessToken == refreshedAccessToken)
        #expect(savedToken.refreshToken == "ref_after_refresh")
        await ECKKeychain.remove(token: savedToken)
    }

    @Test
    func testStaleSuccessfulRefreshCannotReplaceNewerKeychainCredential() async throws {
        let characterId = 60005
        let staleAccessToken = makeJWT(characterId: characterId, tag: "stale", exp: 2524608000)
        let staleToken = try makeTestToken(
            characterId: characterId,
            accessToken: staleAccessToken,
            refreshToken: "ref_stale"
        )
        await ECKKeychain.add(token: staleToken)

        let latestAccessToken = makeJWT(characterId: characterId, tag: "latest", exp: 2524694400)
        let latestToken = try makeTestToken(
            characterId: characterId,
            accessToken: latestAccessToken,
            refreshToken: "ref_latest"
        )
        await ECKKeychain.add(token: latestToken)

        let updateResult = await staleToken.updateToken(
            accessToken: makeJWT(characterId: characterId, tag: "late_response", exp: 2524780800),
            refreshToken: "ref_late_response",
            replacingAccessToken: staleAccessToken,
            refreshToken: "ref_stale"
        )
        let tokens = await ECKKeychain.getTokens(target: .character)
        let savedToken = try #require(tokens.first(where: { $0.characterId == characterId }))

        #expect(updateResult == .superseded)
        #expect(savedToken.accessToken == latestAccessToken)
        #expect(savedToken.refreshToken == "ref_latest")
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

    @Test
    func testStaleInvalidGrantWithUnchangedRefreshTokenSyncsNewerAccessToken() async throws {
        let characterId = 70002
        let latestAccessToken = makeJWT(characterId: characterId, tag: "latest", exp: 2524694400)
        let latestToken = try makeTestToken(
            characterId: characterId,
            accessToken: latestAccessToken,
            refreshToken: "ref_unchanged"
        )
        let staleAccessToken = makeJWT(characterId: characterId, tag: "stale", exp: 2524608000)
        let staleToken = try makeTestToken(
            characterId: characterId,
            accessToken: staleAccessToken,
            refreshToken: "ref_unchanged"
        )
        await ECKKeychain.add(token: latestToken)

        let didSync = await ECKWebService().syncIfNewerTokenExists(for: staleToken)
        let syncedAccessToken = await staleToken.accessToken
        let syncedValidity = await staleToken.isValid

        #expect(didSync)
        #expect(syncedAccessToken == latestAccessToken)
        #expect(syncedValidity)
        await ECKKeychain.remove(token: latestToken)
    }

    @Test
    func testInvalidGrantStillInvalidatesTheCurrentCredential() async throws {
        let characterId = 70003
        let token = try makeTestToken(characterId: characterId, refreshToken: "ref_current")
        await ECKKeychain.add(token: token)
        let accessToken = await token.accessToken
        let refreshToken = await token.refreshToken

        let didInvalidate = await token.markAsInvalid(
            expectedAccessToken: accessToken,
            expectedRefreshToken: refreshToken
        )
        let storedTokens = await ECKKeychain.getTokens(target: .character)
        let storedToken = try #require(storedTokens.first(where: { $0.characterId == characterId }))

        #expect(didInvalidate)
        #expect(storedToken.isValid == false)
        await ECKKeychain.remove(token: storedToken)
    }

    @Test
    func testExpiredResponseFromStaleTokenCannotRewriteKeychainCredential() async throws {
        let characterId = 70004
        let latestAccessToken = makeJWT(characterId: characterId, tag: "latest", exp: 2524694400)
        let latestToken = try makeTestToken(
            characterId: characterId,
            accessToken: latestAccessToken,
            refreshToken: "ref_latest"
        )
        let staleToken = try makeTestToken(
            characterId: characterId,
            accessToken: makeJWT(characterId: characterId, tag: "stale", exp: 2524608000),
            refreshToken: "ref_stale"
        )
        await ECKKeychain.add(token: latestToken)

        await staleToken.markAccessTokenExpired()

        let staleTokenExpired = await staleToken.isExpired
        let storedTokens = await ECKKeychain.getTokens(target: .character)
        let storedToken = try #require(storedTokens.first(where: { $0.characterId == characterId }))
        #expect(staleTokenExpired)
        #expect(storedToken.accessToken == latestAccessToken)
        #expect(storedToken.refreshToken == "ref_latest")
        await ECKKeychain.remove(token: storedToken)
    }

    // MARK: - 3. ECKWebService refreshToken Coalescing & Control Flow Tests
    // (Tests Bug #1: Missing return statement in refreshToken causing Task 2 to fall through to ESI)

    @Test
    func testWebServiceRefreshTokenCoalescingEarlyReturn() async throws {
        let characterId = 80001
        let account = "\(characterId)-character"
        let taskID = UUID()

        let tokenB = try makeTestToken(characterId: characterId, refreshToken: "ref_b", isValid: true)

        // Create a long-running mock refresh task for account
        let inFlightTask: Task<Void, any Error> = Task { @ECKTokenActor in
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        let registeredTask = await ECKTokenActor.registerRefreshTask(inFlightTask, for: account, id: taskID)
        #expect(registeredTask == nil)

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
        await ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
        await ECKKeychain.remove(token: refreshedToken)
    }

    @Test
    func testCoalescedRefreshFailsWhenSharedTaskDoesNotProduceNewToken() async throws {
        let characterId = 80002
        let account = "\(characterId)-character"
        let taskID = UUID()
        let expiredToken = try makeTestToken(characterId: characterId, refreshToken: "ref_expired", exp: 1)
        let completedTask = Task<Void, any Error> { @ECKTokenActor in }
        let registeredTask = await ECKTokenActor.registerRefreshTask(completedTask, for: account, id: taskID)
        #expect(registeredTask == nil)

        var didThrow = false
        do {
            try await ECKWebService().refreshToken(oldToken: expiredToken)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        await ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
    }

    @Test
    func testCoalescedRefreshFailsWhenTokenIsRemovedWhileWaiting() async throws {
        let characterId = 80003
        let account = "\(characterId)-character"
        let taskID = UUID()
        let oldToken = try makeTestToken(characterId: characterId, refreshToken: "ref_old")
        let refreshedToken = try makeTestToken(characterId: characterId, refreshToken: "ref_new")
        await ECKKeychain.add(token: refreshedToken)

        await oldToken.prepareForRemoval()
        let completedTask = Task<Void, any Error> { @ECKTokenActor in }
        let registeredTask = await ECKTokenActor.registerRefreshTask(completedTask, for: account, id: taskID)
        #expect(registeredTask == nil)

        var didThrow = false
        do {
            try await ECKWebService().refreshToken(oldToken: oldToken)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        await ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
        await ECKKeychain.remove(token: refreshedToken)
    }

    @Test
    func testRefreshSyncsLatestKeychainCredentialBeforeSendingRequest() async throws {
        let characterId = 80005
        let staleToken = try makeTestToken(
            characterId: characterId,
            accessToken: makeJWT(characterId: characterId, tag: "stale", exp: 1),
            refreshToken: "ref_stale"
        )
        let latestAccessToken = makeJWT(characterId: characterId, tag: "latest", exp: 2524694400)
        let latestToken = try makeTestToken(
            characterId: characterId,
            accessToken: latestAccessToken,
            refreshToken: "ref_latest"
        )
        await ECKKeychain.add(token: latestToken)

        // The latest token is still valid, so refreshToken must sync and return
        // without submitting the stale refresh token to EVE SSO.
        try await ECKWebService().refreshToken(oldToken: staleToken)

        let syncedAccessToken = await staleToken.accessToken
        let syncedRefreshToken = await staleToken.refreshToken
        #expect(syncedAccessToken == latestAccessToken)
        #expect(syncedRefreshToken == "ref_latest")
        await ECKKeychain.remove(token: latestToken)
    }

    @Test
    func testRefreshPreflightLeavesCurrentCredentialUnchanged() async throws {
        let characterId = 80006
        let currentToken = try makeTestToken(characterId: characterId, refreshToken: "ref_current")
        await ECKKeychain.add(token: currentToken)
        let originalAccessToken = currentToken.accessToken

        let didSync = await ECKWebService().syncWithLatestKeychainToken(for: currentToken)
        let accessToken = currentToken.accessToken
        let refreshToken = currentToken.refreshToken
        #expect(didSync == false)
        #expect(accessToken == originalAccessToken)
        #expect(refreshToken == "ref_current")
        await ECKKeychain.remove(token: currentToken)
    }

    @Test
    func testRemovingTokenKeepsRefreshRegisteredUntilTaskFinishes() async throws {
        let characterId = 80004
        let account = "\(characterId)-character"
        let token = try makeTestToken(characterId: characterId, refreshToken: "ref_in_flight")
        let gate = ECKTokenRefreshTestGate()
        let taskID = UUID()
        let otherAccount = "\(characterId + 1)-corp"
        let otherTaskID = UUID()
        let otherTask: Task<Void, any Error> = Task { @ECKTokenActor in }
        try await otherTask.value
        let registeredOtherTask = await ECKTokenActor.registerRefreshTask(otherTask, for: otherAccount, id: otherTaskID)
        #expect(registeredOtherTask == nil)

        let inFlightTask: Task<Void, any Error> = Task { @ECKTokenActor in
            defer {
                ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
            }
            await gate.pause()
        }
        let registeredInFlightTask = await ECKTokenActor.registerRefreshTask(inFlightTask, for: account, id: taskID)
        #expect(registeredInFlightTask == nil)
        await gate.waitUntilPaused()

        await token.prepareForRemoval()
        let registeredTaskAfterRemoval = await ECKTokenActor.refreshTask(for: account)
        let otherAccountTask = await ECKTokenActor.refreshTask(for: otherAccount)
        #expect(registeredTaskAfterRemoval != nil)
        #expect(otherAccountTask != nil)

        await gate.open()
        _ = try? await inFlightTask.value
        let registeredTaskAfterCompletion = await ECKTokenActor.refreshTask(for: account)
        #expect(registeredTaskAfterCompletion == nil)
        await ECKTokenActor.clearRefreshTask(for: otherAccount, matching: otherTaskID)
    }

    // MARK: - 4. Task Coalescing & Concurrent Refresh Stress Tests
    // (Tests Bug #2: Task coalescing across multiple ECKToken instances for same character)

    @Test
    func testConcurrentRefreshTaskCoalescingForSameAccount() async throws {
        let account = "10001-character-\(UUID().uuidString)"
        let taskID = UUID()

        // Create a long-running mock refresh task
        let refreshTask: Task<Void, any Error> = Task { @ECKTokenActor in
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        let existingTask = await ECKTokenActor.registerRefreshTask(refreshTask, for: account, id: taskID)
        #expect(existingTask == nil)

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
        await ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
    }

    @Test
    func testRefreshTaskRegistrationRejectsSecondTaskForSameAccount() async throws {
        let account = "refresh-register-\(UUID().uuidString)"
        let firstTaskID = UUID()
        let secondTaskID = UUID()
        let firstTask: Task<Void, any Error> = Task { @ECKTokenActor in
            try await Task.sleep(nanoseconds: 60_000_000_000)
        }
        let secondTask: Task<Void, any Error> = Task { @ECKTokenActor in }

        let existingBeforeRegistration = await ECKTokenActor.registerRefreshTask(firstTask, for: account, id: firstTaskID)
        let existingAfterSecondRegistration = await ECKTokenActor.registerRefreshTask(secondTask, for: account, id: secondTaskID)
        let registeredTask = await ECKTokenActor.refreshTask(for: account)

        #expect(existingBeforeRegistration == nil)
        #expect(existingAfterSecondRegistration != nil)
        #expect(registeredTask != nil)
        firstTask.cancel()
        secondTask.cancel()
        _ = try? await firstTask.value
        await ECKTokenActor.clearRefreshTask(for: account, matching: firstTaskID)
    }

    @Test
    func testMultiAccountConcurrentRefreshIsolation() async throws {
        let characterIds = [20001, 20002, 20003, 20004, 20005]
        let accounts = characterIds.map { "\($0)-character-\(UUID().uuidString)" }

        // Launch concurrent refresh task registrations across 5 different characters
        await withTaskGroup(of: Void.self) { group in
            for account in accounts {
                group.addTask {
                    let taskID = UUID()
                    let task: Task<Void, any Error> = Task { @ECKTokenActor in
                        try await Task.sleep(nanoseconds: 50_000_000)
                    }
                    let existingTask = await ECKTokenActor.registerRefreshTask(task, for: account, id: taskID)
                    #expect(existingTask == nil)

                    // Verify task registered specifically for this account
                    let retrievedTask = await ECKTokenActor.refreshTask(for: account)
                    #expect(retrievedTask != nil)
                    
                    _ = try? await task.value
                    await ECKTokenActor.clearRefreshTask(for: account, matching: taskID)
                }
            }
        }

        // Verify clean teardown for all accounts
        for account in accounts {
            let task = await ECKTokenActor.refreshTask(for: account)
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

        let registeredOldTask = await ECKTokenActor.registerRefreshTask(oldTask, for: account, id: oldID)
        #expect(registeredOldTask == nil)

        // Simulate the old task finishing, then allow a new generation to register.
        await ECKTokenActor.clearRefreshTask(for: account, matching: oldID)
        let registeredNewTask = await ECKTokenActor.registerRefreshTask(newTask, for: account, id: newID)
        #expect(registeredNewTask == nil)

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
