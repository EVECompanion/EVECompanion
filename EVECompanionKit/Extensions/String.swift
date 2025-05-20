//
//  String.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 24.05.24.
//

import Foundation

extension String {

    public func convertToAttributed() -> AttributedString {
        guard let data = data(using: .utf16) else {
          return AttributedString(self)
        }
        
        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) else {
            return AttributedString(self)
        }
        
        guard let modifiedAttributedString = attributedString.mutableCopy() as? NSMutableAttributedString else {
            return AttributedString(attributedString)
        }
        
        attributedString.enumerateAttributes(in: NSRange(location: 0,
                                                         length: modifiedAttributedString.length)) { attributes, range, _ in
            for(key, value) in attributes {
                switch key {
                    
                case .font:
                    modifiedAttributedString.removeAttribute(.font, range: range)
                    
                case .foregroundColor:
                    modifiedAttributedString.removeAttribute(.foregroundColor, range: range)
                    
                case .kern:
                    modifiedAttributedString.removeAttribute(.kern, range: range)
                    
                case .link:
                    guard let valueURL = value as? URL else {
                        continue
                    }
                    
                    if valueURL.scheme?.lowercased() == "showinfo",
                       let showInfoComponents = URLComponents(url: valueURL,
                                                              resolvingAgainstBaseURL: false),
                       let typeId = Int(showInfoComponents.path),
                       let url = URL(string: "evecompanion://showinfo/\(typeId)") {
                        modifiedAttributedString.removeAttribute(.link, range: range)
                        modifiedAttributedString.addAttribute(.link, value: url, range: range)
                    }
                    
                default:
                    continue
                    
                }
            }
        }
        
        return AttributedString(modifiedAttributedString)
    }
    
}
