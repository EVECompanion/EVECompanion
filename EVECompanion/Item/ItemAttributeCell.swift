//
//  ItemAttributeCell.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 03.04.25.
//

import SwiftUI
import EVECompanionKit

struct ItemAttributeCell: View {
    
    let attribute: ECKSDEManager.ItemAttribute
    
    var body: some View {
        if let unit = attribute.unit,
           case .typeId = unit {
            let item = ECKItem(typeId: Int(attribute.value))
            NavigationLink(value: AppScreen.item(item)) {
                HStack {
                    Text(attribute.displayName)
                    Spacer()
                    ECImage(id: item.typeId,
                            category: .types)
                    .frame(width: 40, height: 40)
                    
                    Text(item.name)
                }
            }
        } else if let unit = attribute.unit,
                  case .groupId = unit {
            HStack {
                Text(attribute.displayName)
                Spacer()
                Text(ECKSDEManager.shared.groupName(for: Int(attribute.value)))
            }
        } else if let unit = attribute.unit,
                  case .attributeId = unit {
            let attribute = ECKSDEManager.shared.getAttribute(id: Int(attribute.value))
            HStack {
                if let imageName = imageName(attributeId: Int(attribute.attributeId)) {
                    Image(imageName)
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                Text(attribute.attributeName)
            }
        } else {
            HStack {
                Text(attribute.displayName)
                Spacer()
                if let unit = attribute.unit {
                    Text(unit.formatted(attribute.value))
                } else {
                    Text(ECFormatters.attributeValue(attribute.value))
                }
            }
        }
    }
    
    func imageName(attributeId: Int) -> String? {
        switch attributeId {
        case 164:
            return "Attributes/charisma"
        case 165:
            return "Attributes/intelligence"
        case 166:
            return "Attributes/memory"
        case 167:
            return "Attributes/perception"
        case 168:
            return "Attributes/willpower"
        default:
            return nil
        }
    }
    
}

#Preview {
    List {
        ItemAttributeCell(attribute: (id: 0,
                                      name: "Armor EM Damage Resistance",
                                      displayName: "Armor EM Damage Resistance",
                                      value: 50,
                                      unit: EVEUnit("Percentage")))
    }
    .listStyle(.plain)
}
