//
//  ECKDogmaEffect.swift
//  EVECompanionKit
//
//  Created by Jonas Schlabertz on 28.05.25.
//

import Foundation
import Yams

public class ECKDogmaEffect {
    
    public enum Category: Int {
        
        case passive = 0
        case active = 1
        case target = 2
        case area = 3
        case online = 4
        case overload = 5
        case dungeon = 6
        case system = 7
        
        init(rawValue: Int?) {
            guard let rawValue else {
                self = .passive
                return
            }
            
            switch rawValue {
            case 1:
                self = .active
            case 2:
                self = .target
            case 3:
                self = .area
            case 4:
                self = .online
            case 5:
                self = .overload
            case 6:
                self = .dungeon
            case 7:
                self = .system
            default:
                self = .passive
            }
        }
        
        public var title: String {
            switch self {
            case .passive:
                return "Passive"
            case .active:
                return "Active"
            case .target:
                return "Target"
            case .area:
                return "Area"
            case .online:
                return "Online"
            case .overload:
                return "Overload"
            case .dungeon:
                return "Dungeon"
            case .system:
                return "System"
            }
        }
        
    }
    
    let id: Int
    let name: String
    let category: Category
    let modifierInfo: [[String: Any]]
    
    init(data: ECKSDEManager.FetchedEffect) {
        self.id = data.effectId
        self.name = data.effectName
        self.category = .init(rawValue: data.effectCategory)
        
        guard data.modifierInfo != "null\n...\n" else {
            self.modifierInfo = []
            return
        }
        
        do {
            let decodedInfo = try Yams.load(yaml: data.modifierInfo)
            guard let modifierInfo = decodedInfo as? [[String: Any]] else {
                logger.warning("Cannot read modifier info from \(String(describing: decodedInfo))")
                self.modifierInfo = []
                return
            }
            
            self.modifierInfo = modifierInfo
        } catch {
            logger.error("Cannot decode modifier info: \(error)")
            self.modifierInfo = []
        }
    }
    
}
