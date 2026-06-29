//
//  Date+Parsing.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import Foundation

enum ECKDateParser {

    static func esiDateOnly(_ dateString: String, codingPath: [any CodingKey] = []) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                                    debugDescription: "Invalid ESI date-only value \(dateString)"))
        }

        return date
    }

}
