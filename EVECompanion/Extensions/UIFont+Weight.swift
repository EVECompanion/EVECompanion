//
//  UIFont+Weight.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 05.04.25.
//

import UIKit

extension UIFont {
    var weight: UIFont.Weight {
        guard let weightNumber = traits[.weight] as? Double else {
            return .regular
        }
        
        let weight = UIFont.Weight(rawValue: weightNumber)
        return weight
    }

    private var traits: [UIFontDescriptor.TraitKey: Any] {
        return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
            ?? [:]
    }
}
