//
//  PlanetaryColonyPinView.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 22.10.24.
//

import SwiftUI
import Charts
import EVECompanionKit

struct PlanetaryColonyPinView: View {
    
    let pin: ECKPlanetaryColonyPin
    
    var body: some View {
        NavigationLink(value: AppScreen.item(pin.item)) {
            HStack {
                ECImage(id: pin.item.typeId,
                        category: .types)
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(pin.item.name)
                        .font(.headline)
                    
                    if let capacity = pin.item.capacity, capacity > 0 {
                        Text("\(ECFormatters.attributeValue(pin.contentVolume))/\(ECFormatters.attributeValue(capacity)) m³")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        
        Group {
            if let extractorDetails = pin.extractorDetails,
               let product = extractorDetails.product {
                Text("Product")
                    .font(.headline)
                
                NavigationLink(value: AppScreen.item(product)) {
                    HStack {
                        ECImage(id: product.typeId,
                                category: .types)
                        .frame(width: 40, height: 40)
                        
                        Text(product.name)
                            .font(.headline)
                    }
                }
            }
            
            if pin.extractorValues.isEmpty == false {
                Chart(pin.extractorValues, id: \.date) {
                    BarMark(x: .value("x", $0.date),
                            y: .value("y", $0.units),
                            width: 2)
                }
                .chartXAxis {
                    AxisMarks(values: [pin.extractorStartTime, pin.extractorEndTime].compactMap({ $0 })) { _ in
                        
                        AxisValueLabel {
                            Text("")
                        }
                        
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .overlay(alignment: .bottom) {
                    HStack {
                        if let startTime = pin.extractorStartTime {
                            Text(ECFormatters.dateFormatter(date: startTime))
                                .padding(.leading, 4)
                        }
                        
                        Spacer()
                        
                        if let endTime = pin.extractorEndTime {
                            Text(ECFormatters.dateFormatter(date: endTime))
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            }
            
            if let contents = pin.contents, contents.isEmpty == false {
                Text("Storage")
                    .font(.headline)
                
                ForEach(contents, id: \.item.typeId) { content in
                    NavigationLink(value: AppScreen.item(content.item)) {
                        HStack {
                            ECImage(id: content.item.typeId,
                                    category: .types)
                            .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text("\(ECFormatters.attributeValue(Float(content.amount))) \(content.item.name)")
                                Text("\(ECFormatters.attributeValue(content.volume)) m³")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            
            if let schematic = pin.schematic {
                schematicView(schematic: schematic)
            }
            
            if pin.warnings.isEmpty == false {
                VStack(alignment: .leading) {
                    PlanetaryColonyWarningsView(warnings: pin.warnings)
                }
            }
        }
    }
    
    @ViewBuilder
    private func schematicView(schematic: ECKPlanetSchematic) -> some View {
        Text("Cycle Time: \(ECFormatters.timeInterval(timeInterval: TimeInterval(schematic.cycleTime)))")
            .font(.headline)
        
        if schematic.inputs.isEmpty == false {
            ForEach(schematic.inputs, id: \.self) { input in
                NavigationLink(value: AppScreen.item(input.item)) {
                    HStack {
                        ECImage(id: input.item.typeId,
                                category: .types)
                        .frame(width: 40, height: 40)
                        
                        Text("Input: \(ECFormatters.attributeValue(Float(input.quantity))) \(input.item.name)")
                    }
                    .padding(.vertical)
                }
            }
        }
        
        NavigationLink(value: AppScreen.item(schematic.output.item)) {
            HStack {
                ECImage(id: schematic.output.item.typeId,
                        category: .types)
                .frame(width: 40, height: 40)
                
                Text("Output: \(ECFormatters.attributeValue(Float(schematic.output.quantity))) \(schematic.output.item.name)")
            }
            .padding(.vertical)
        }
    }
}

#Preview("Industry Facility") {
    List {
        PlanetaryColonyPinView(pin: .dummy1)
    }
}

#Preview("Storage Facility") {
    List {
        PlanetaryColonyPinView(pin: .dummy2)
    }
}

#Preview("Extractor") {
    List {
        PlanetaryColonyPinView(pin: .dummy3)
    }
}

#Preview("Command Center") {
    List {
        PlanetaryColonyPinView(pin: .dummy4)
    }
}
