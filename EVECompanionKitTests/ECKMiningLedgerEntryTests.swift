//
//  ECKMiningLedgerEntryTests.swift
//  EVECompanionKitTests
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import Foundation
import Testing
@testable import EVECompanionKit

struct ECKMiningLedgerEntryTests {

    @Test
    func decodesMiningLedgerDateOnlyResponse() throws {
        let data = """
        [
            {
                "date": "2026-06-27",
                "quantity": 125000,
                "solar_system_id": 30000142,
                "type_id": 1230
            }
        ]
        """.data(using: .utf8)!

        let entries = try JSONDecoder().decode([ECKMiningLedgerEntry].self, from: data)
        let entry = try #require(entries.first)

        #expect(entry.quantity == 125_000)
        #expect(entry.solarSystem.id == 30000142)
        #expect(entry.item.typeId == 1230)

        let components = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!,
                                                                         from: entry.date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 27)
    }

    @Test
    func groupsMiningLedgerEntriesIntoDailyOreStats() throws {
        let firstDate = try #require(Self.date(year: 2026, month: 6, day: 27))
        let secondDate = try #require(Self.date(year: 2026, month: 6, day: 26))
        let veldspar = Self.item(typeId: 1230, name: "Veldspar", volume: 0.1)
        let scordite = Self.item(typeId: 1228, name: "Scordite", volume: 0.15)
        let entries: [ECKMiningLedgerEntry] = [
            .init(date: firstDate,
                  quantity: 10,
                  solarSystem: .jita,
                  item: veldspar),
            .init(date: firstDate,
                  quantity: 15,
                  solarSystem: .jita,
                  item: veldspar),
            .init(date: firstDate,
                  quantity: 4,
                  solarSystem: .jita,
                  item: scordite),
            .init(date: secondDate,
                  quantity: 5,
                  solarSystem: .jita,
                  item: veldspar)
        ]

        let summaries = ECKMiningLedgerDaySummary.summaries(
            from: entries,
            averagePrices: [
                veldspar.typeId: 100,
                scordite.typeId: 200
            ]
        )
        let firstDaySummary = try #require(summaries.first)
        let veldsparSummary = try #require(firstDaySummary.ores.first { $0.item == veldspar })
        let scorditeSummary = try #require(firstDaySummary.ores.first { $0.item == scordite })

        #expect(summaries.count == 2)
        #expect(firstDaySummary.date == firstDate)
        #expect(firstDaySummary.ores.count == 2)
        #expect(veldsparSummary.quantity == 25)
        #expect(abs(veldsparSummary.volume - 2.5) < 0.0001)
        #expect(veldsparSummary.totalWorth == 2500)
        #expect(scorditeSummary.quantity == 4)
        #expect(abs(scorditeSummary.volume - 0.6) < 0.0001)
        #expect(scorditeSummary.totalWorth == 800)
        #expect(abs(firstDaySummary.totalVolume - 3.1) < 0.0001)
        #expect(firstDaySummary.totalWorth == 3300)
    }

    @Test
    func decodesMarketHistoryDateOnlyResponseWithSharedParser() throws {
        let data = """
        [
            {
                "average": 100.0,
                "date": "2026-06-26",
                "highest": 125.0,
                "lowest": 75.0,
                "order_count": 10,
                "volume": 5000
            }
        ]
        """.data(using: .utf8)!

        let entries = try JSONDecoder().decode([ECKMarketHistoryEntry].self, from: data)
        let entry = try #require(entries.first)

        #expect(entry.average == 100)
        #expect(entry.highest == 125)
        #expect(entry.lowest == 75)
        #expect(entry.orderCount == 10)
        #expect(entry.volume == 5000)

        let components = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!,
                                                                         from: entry.date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 26)
    }

    private static func date(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: .init(year: year, month: month, day: day))
    }

    private static func item(typeId: Int, name: String, volume: Float) -> ECKItem {
        ECKItem(itemData: (typeId: typeId,
                           name: name,
                           description: nil,
                           mass: nil,
                           volume: volume,
                           capacity: nil,
                           radius: nil,
                           iconId: nil))
    }

}
