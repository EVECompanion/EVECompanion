//
//  MiningLedgerDaySummaryCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 28.06.26.
//

import Charts
import SwiftUI
import EVECompanionKit

struct MiningLedgerDaySummaryCell: View {

    let summary: ECKMiningLedgerDaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            oreDistributionChart
            oreBreakdown
        }
        .padding(.vertical, 6)
    }

}

struct MiningLedgerDaySummaryHeader: View {

    let summary: ECKMiningLedgerDaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ECFormatters.dateOnlyFormatter(date: summary.date))
                .font(.title2)

            Text("Total Volume: \(EVEUnit.volume.formatted(Float(summary.totalVolume)))")
                .font(.headline)

            Text("Total Worth: \(formattedIsk(summary.totalWorth))")
                .font(.headline)
        }
    }

    private func formattedIsk(_ value: Double?) -> String {
        guard let value else {
            return "Unknown"
        }

        return "\(ECFormatters.iskLong(value)) ISK"
    }

}

private extension MiningLedgerDaySummaryCell {

    var oreDistributionChart: some View {
        Chart(summary.ores) { oreSummary in
            BarMark(
                x: .value("Volume", oreSummary.volume),
                y: .value("Ore", oreSummary.item.name)
            )
            .foregroundStyle(by: .value("Ore", oreSummary.item.name))
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks { value in
                if let volume = value.as(Double.self) {
                    AxisValueLabel {
                        Text(EVEUnit.volume.formatted(Float(volume)))
                    }
                }
                
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
            }
        }
    }

    var oreBreakdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(summary.ores.enumerated()), id: \.element.id) { index, oreSummary in
                NavigationLink(value: AppScreen.item(oreSummary.item)) {
                    HStack(alignment: .top, spacing: 12) {
                        ECImage(id: oreSummary.item.typeId,
                                category: .types)
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(oreSummary.item.name)
                                .font(.headline)

                            Text("\(EVEUnit.oreUnits.formatted(Float(oreSummary.quantity))) mined")

                            Text("Volume: \(EVEUnit.volume.formatted(Float(oreSummary.volume)))")
                                .foregroundStyle(.secondary)

                            Text("Worth: \(formattedIsk(oreSummary.totalWorth))")
                                .foregroundStyle(.secondary)

                            Text("Average Price: \(formattedIsk(oreSummary.averageUnitPrice))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if index < summary.ores.count - 1 {
                    Divider()
                }
            }
        }
    }

    func formattedIsk(_ value: Double?) -> String {
        guard let value else {
            return "Unknown"
        }

        return "\(ECFormatters.iskLong(value)) ISK"
    }

}

#Preview {
    List {
        Section {
            MiningLedgerDaySummaryCell(summary: .dummy)
        } header: {
            MiningLedgerDaySummaryHeader(summary: .dummy)
        }
    }
}
