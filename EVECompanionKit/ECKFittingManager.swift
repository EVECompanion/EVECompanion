//
//  ECKFittingManager.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 25.05.25.
//

import Foundation
public import Combine

public class ECKFittingManager: ObservableObject, @unchecked Sendable {
    
    public let character: ECKCharacter
    public let isPreview: Bool
    
    @Published var loadedLocalFittings: [ECKCharacterFitting] = []
    public var localFittings: [ECKCharacterFitting] {
        if searchText.isEmpty == false {
            return loadedLocalFittings.filter { fitting in
                return fitting.name.lowercased().contains(searchText.lowercased())
                || fitting.ship.item.name.lowercased().contains(searchText.lowercased())
            }
        } else {
            return loadedLocalFittings
        }
    }
    
    @Published public var searchText: String = ""
    
    public init(character: ECKCharacter, isPreview: Bool = false) {
        self.character = character
        self.isPreview = isPreview
        Task { @MainActor in
            await loadFittings()
        }
    }
    
    @MainActor
    public func loadFittings() async {
        do {
            let fittingsDir = try getFittingsDirectory()
            let fittingURLs = try FileManager.default.contentsOfDirectory(at: fittingsDir,
                                                                          includingPropertiesForKeys: nil)
            
            var fittings: [ECKCharacterFitting] = []
            let decoder = JSONDecoder()
            
            for fittingURL in fittingURLs {
                do {
                    let fittingData = try Data(contentsOf: fittingURL)
                    let fitting = try decoder.decode(ECKCharacterFitting.self, from: fittingData)
                    fittings.append(fitting)
                } catch {
                    logger.error("Cannot load local fitting: \(error)")
                    continue
                }
            }
            
            self.loadedLocalFittings = fittings
        } catch {
            logger.error("Error loading local fittings: \(error)")
            return
        }
    }
    
    private func getDocumentsDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
    }
    
    private func getFittingsDirectory() throws -> URL {
        let documentsDir = try getDocumentsDirectory()
        let fittingsDir = documentsDir.appendingPathComponent("fittings", isDirectory: true)
        
        if FileManager.default.fileExists(atPath: fittingsDir.path) == false {
            try FileManager.default.createDirectory(at: fittingsDir, withIntermediateDirectories: true)
        }
        
        return fittingsDir
    }
    
    private func getFittingFileURL(_ fitting: ECKCharacterFitting) throws -> URL {
        let fittingsDirectoryUrl = try getFittingsDirectory()
        return fittingsDirectoryUrl.appendingPathComponent("\(fitting.fittingId.uuidString).json", isDirectory: false)
    }
    
    @MainActor
    public func createFitting(with ship: ECKItem) -> ECKCharacterFitting {
        let newFitting = ECKCharacterFitting(ship: ship)
        self.loadedLocalFittings.append(newFitting)
        saveFitting(newFitting)
        return newFitting
    }
    
    @MainActor
    public func importFitting(_ fitting: ECKCharacterFitting) {
        self.loadedLocalFittings.append(fitting)
        saveFitting(fitting)
    }
    
    public func saveFitting(_ fitting: ECKCharacterFitting) {
        do {
            let fittingFileURL = try getFittingFileURL(fitting)
            let data = try JSONEncoder().encode(fitting)
            try data.write(to: fittingFileURL, options: .atomic)
        } catch {
            logger.error("Error saving fitting: \(error)")
        }
    }
    
    public func deleteFit(_ fittingToRemove: ECKCharacterFitting) {
        do {
            let fittingFileURL = try getFittingFileURL(fittingToRemove)
            try FileManager.default.removeItem(at: fittingFileURL)
        } catch {
            logger.error("Error deleting fit: \(error)")
        }
        
        self.loadedLocalFittings.removeAll { fitting in
            return fitting.id == fittingToRemove.id
        }
    }
    
}

/// Reads and writes the clipboard EFT representation used by EVE Online.
public enum ECKEFTFormat {
    enum ItemKind {
        case module(ECKCharacterFitting.ModuleSlotType)
        case drone
        case fighter
        case other
    }

    public enum ImportError: LocalizedError, Equatable {
        case invalidHeader
        case unknownItem(String)

        public var errorDescription: String? {
            switch self {
            case .invalidHeader:
                return "The EFT text must start with [Ship, Fit Name]."
            case .unknownItem(let name):
                return "Could not find \(name) in the local EVE data."
            }
        }
    }

    public static func importFitting(from text: String) throws -> ECKCharacterFitting {
        try importFitting(from: text,
                          resolveItem: { ECKSDEManager.shared.item(named: $0) },
                          classifyItem: { item in
            if let slotType = item.slotType {
                return .module(slotType)
            }
            if item.isDrone {
                return .drone
            }
            if item.isFighter {
                return .fighter
            }
            return .other
        })
    }

    static func importFitting(from text: String,
                              resolveItem: (String) -> ECKItem?,
                              classifyItem: (ECKItem) -> ItemKind) throws -> ECKCharacterFitting {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        guard let header = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
              header.hasPrefix("["), header.hasSuffix("]") else {
            throw ImportError.invalidHeader
        }

        let fields = header.dropFirst().dropLast().split(separator: ",", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard let shipName = fields.first, shipName.isEmpty == false,
              let ship = resolveItem(shipName) else {
            throw ImportError.unknownItem(fields.first ?? "ship")
        }
        let fittingName = fields.count > 1 && fields[1].isEmpty == false ? fields[1] : shipName
        let fitting = ECKCharacterFitting(fittingId: UUID(),
                                          description: "",
                                          esiFittingId: nil,
                                          items: [],
                                          name: fittingName,
                                          ship: ship)

        var cargoSectionStarted = false
        var consecutiveBlankLines = 0
        for line in lines.drop(while: { $0 != header }).dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                consecutiveBlankLines += 1
                if consecutiveBlankLines >= 2 { cargoSectionStarted = true }
                continue
            }
            consecutiveBlankLines = 0
            if trimmed.hasPrefix("[Empty ") { continue }

            let components = trimmed.components(separatedBy: ", ")
            let modulePart = components[0].replacingOccurrences(of: "/offline", with: "")
                .trimmingCharacters(in: .whitespaces)
            let (moduleName, quantity) = splitQuantity(modulePart)
            guard let item = resolveItem(moduleName) else {
                throw ImportError.unknownItem(moduleName)
            }

            switch classifyItem(item) {
            case .drone:
                fitting.drones.append(.init(flag: .DroneBay, quantity: quantity, item: item))
            case .fighter:
                let flag = ECKItemLocationFlag(rawValue: "FighterTube\(fitting.fighters.count)") ?? .FighterTube0
                fitting.fighters.append(.init(flag: flag, quantity: quantity, item: item))
            case .other where cargoSectionStarted:
                fitting.cargoItems.append(.init(flag: .Cargo, quantity: quantity, item: item))
            case .module(let slot) where cargoSectionStarted == false:
                let slotIndex: Int
                switch slot {
                case .low: slotIndex = fitting.lowSlotModules.count
                case .mid: slotIndex = fitting.midSlotModules.count
                case .high: slotIndex = fitting.highSlotModules.count
                case .rig: slotIndex = fitting.rigs.count
                case .subsystem: slotIndex = fitting.subsystems.count
                }
                let prefix: String
                switch slot {
                case .low: prefix = "LoSlot"
                case .mid: prefix = "MedSlot"
                case .high: prefix = "HiSlot"
                case .rig: prefix = "RigSlot"
                case .subsystem: prefix = "SubSystemSlot"
                }
                let module = ECKCharacterFittingItem(flag: .init(rawValue: "\(prefix)\(slotIndex)")!,
                                                     quantity: 1,
                                                     item: item)
                if components[0].contains("/offline") { module.state = .offline }
                if components.count > 1 {
                    let chargeName = components.dropFirst().joined(separator: ", ")
                    let (cleanChargeName, _) = splitQuantity(chargeName.trimmingCharacters(in: .whitespaces))
                    guard let charge = resolveItem(cleanChargeName) else {
                        throw ImportError.unknownItem(cleanChargeName)
                    }
                    module.charge = .init(flag: module.flag, quantity: 1, item: charge)
                }
                switch slot {
                case .low: fitting.lowSlotModules.append(module)
                case .mid: fitting.midSlotModules.append(module)
                case .high: fitting.highSlotModules.append(module)
                case .rig: fitting.rigs.append(module)
                case .subsystem: fitting.subsystems.append(module)
                }
            case .module, .other:
                // EFT's module sections only contain fitted modules; un-slotted items belong in cargo.
                fitting.cargoItems.append(.init(flag: .Cargo, quantity: quantity, item: item))
            }
        }
        return fitting
    }

    public static func export(_ fitting: ECKCharacterFitting) -> String {
        func itemLine(_ item: ECKCharacterFittingItem, quantity: Bool = false) -> String {
            var line = item.item.name
            if item.state == .offline { line += " /offline" }
            if let charge = item.charge { line += ", \(charge.item.name)" }
            if quantity || item.quantity > 1 { line += " x\(item.quantity)" }
            return line
        }
        let sections: [[String]] = [
            fitting.lowSlotModules.map { itemLine($0) },
            fitting.midSlotModules.map { itemLine($0) },
            fitting.highSlotModules.map { itemLine($0) },
            fitting.rigs.map { itemLine($0) },
            fitting.subsystems.map { itemLine($0) },
            fitting.fighters.map { itemLine($0, quantity: true) } + fitting.drones.map { itemLine($0, quantity: true) }
        ]
        var result = "[\(fitting.ship.item.name), \(fitting.name)]"
        for section in sections where section.isEmpty == false {
            result += "\n\n" + section.joined(separator: "\n")
        }
        if fitting.cargoItems.isEmpty == false {
            result += "\n\n\n" + fitting.cargoItems.map { itemLine($0, quantity: true) }.joined(separator: "\n")
        }
        return result
    }

    private static func splitQuantity(_ value: String) -> (String, Int) {
        guard let separator = value.range(of: " x", options: .backwards),
              let quantity = Int(value[separator.upperBound...]), quantity > 0 else {
            return (value, 1)
        }
        return (String(value[..<separator.lowerBound]), quantity)
    }
}
