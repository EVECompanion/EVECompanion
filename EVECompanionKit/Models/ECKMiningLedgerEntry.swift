//
//  ECKMiningLedgerEntry.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import Foundation

public final class ECKMiningLedgerEntry: Decodable, Identifiable, Sendable {

    private enum CodingKeys: String, CodingKey {
        case date
        case quantity
        case solarSystem = "solar_system_id"
        case item = "type_id"
    }

    public var id: String {
        return "\(Int(date.timeIntervalSince1970))-\(solarSystem.id)-\(item.typeId)"
    }

    public static let dummy1: ECKMiningLedgerEntry = .init(date: .now - .fromDays(days: 1),
                                                           quantity: 125_000,
                                                           solarSystem: .jita,
                                                           item: .init(typeId: 1230))

    public static let dummy2: ECKMiningLedgerEntry = .init(date: .now - .fromDays(days: 2),
                                                           quantity: 48_500,
                                                           solarSystem: .init(solarSystemId: 30000144),
                                                           item: .init(typeId: 1228))

    public let date: Date
    public let quantity: Int
    public let solarSystem: ECKSolarSystem
    public let item: ECKItem

    init(date: Date,
         quantity: Int,
         solarSystem: ECKSolarSystem,
         item: ECKItem) {
        self.date = date
        self.quantity = quantity
        self.solarSystem = solarSystem
        self.item = item
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .date)
        self.date = try ECKDateParser.esiDateOnly(dateString, codingPath: [CodingKeys.date])
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.solarSystem = try container.decode(ECKSolarSystem.self, forKey: .solarSystem)
        self.item = try container.decode(ECKItem.self, forKey: .item)
    }

}

public struct ECKMiningLedgerOreSummary: Identifiable, Sendable {

    public var id: Int {
        item.typeId
    }

    public let item: ECKItem
    public let quantity: Int
    public let averageUnitPrice: Double?

    public init(item: ECKItem,
                quantity: Int,
                averageUnitPrice: Double?) {
        self.item = item
        self.quantity = quantity
        self.averageUnitPrice = averageUnitPrice
    }

    public var volume: Double {
        Double(item.volume ?? 0) * Double(quantity)
    }

    public var totalWorth: Double? {
        averageUnitPrice.map { $0 * Double(quantity) }
    }

}

public struct ECKMiningLedgerDaySummary: Identifiable, Sendable {

    public static let dummy = ECKMiningLedgerDaySummary(
        date: .now,
        ores: [
            .init(item: ECKMiningLedgerEntry.dummy1.item,
                  quantity: ECKMiningLedgerEntry.dummy1.quantity,
                  averageUnitPrice: 8),
            .init(item: ECKMiningLedgerEntry.dummy2.item,
                  quantity: ECKMiningLedgerEntry.dummy2.quantity,
                  averageUnitPrice: 12)
        ]
    )

    public var id: Date {
        date
    }

    public let date: Date
    public let ores: [ECKMiningLedgerOreSummary]

    public init(date: Date,
                ores: [ECKMiningLedgerOreSummary]) {
        self.date = date
        self.ores = ores
    }

    public var totalVolume: Double {
        ores.reduce(0) { partialResult, oreSummary in
            partialResult + oreSummary.volume
        }
    }

    public var totalWorth: Double? {
        guard ores.allSatisfy({ $0.totalWorth != nil }) else {
            return nil
        }

        return ores.reduce(0) { partialResult, oreSummary in
            partialResult + (oreSummary.totalWorth ?? 0)
        }
    }

    static func summaries(from entries: [ECKMiningLedgerEntry],
                          averagePrices: [Int: Double]) -> [ECKMiningLedgerDaySummary] {
        let calendar = Calendar.eve
        let entriesByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        return entriesByDay.map { date, entries in
            let entriesByTypeId = Dictionary(grouping: entries) { entry in
                entry.item.typeId
            }

            let ores = entriesByTypeId.compactMap { typeId, entries -> ECKMiningLedgerOreSummary? in
                guard let item = entries.first?.item else {
                    return nil
                }

                let quantity = entries.reduce(0) { partialResult, entry in
                    partialResult + entry.quantity
                }

                return ECKMiningLedgerOreSummary(item: item,
                                                 quantity: quantity,
                                                 averageUnitPrice: averagePrices[typeId])
            }
            .sorted { lhs, rhs in
                lhs.item.name < rhs.item.name
            }

            return ECKMiningLedgerDaySummary(date: date, ores: ores)
        }
        .sorted { lhs, rhs in
            lhs.date > rhs.date
        }
    }

}

private extension Calendar {

    static var eve: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

}
