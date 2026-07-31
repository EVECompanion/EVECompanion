//
//  String.swift
//  EVECompanion
//
//  Created by Jonas Schlabertz on 24.05.24.
//

import Foundation
public import UIKit
import SwiftSoup

extension String {

    public func convertToAttributed() -> AttributedString {
            do {
                let document = try SwiftSoup.parseBodyFragment(self)

                guard let body = document.body() else {
                    return AttributedString(self)
                }

                var result = AttributedString()

                for node in body.getChildNodes() {
                    result.append(try attributedString(from: node))
                }

                return result

            } catch {
                return AttributedString(self)
            }
        }

        private func attributedString(from node: Node) throws -> AttributedString {
            if let textNode = node as? TextNode {
                return AttributedString(textNode.getWholeText())
            }

            if let element = node as? SwiftSoup.Element {
                let tag = element.tagName()

                switch tag.lowercased() {
                case "br":
                    return AttributedString("\n")

                case "b", "strong":
                    var result = AttributedString()
                    
                    for child in element.getChildNodes() {
                        result.append(try attributedString(from: child))
                    }
                    
                    result.inlinePresentationIntent = .stronglyEmphasized
                    
                    return result

                case "a":
                    var result = AttributedString()

                    for child in element.getChildNodes() {
                        result.append(try attributedString(from: child))
                    }

                    let href = try element.attr("href")

                    if href.lowercased().hasPrefix("showinfo:"),
                       let id = href.split(separator: ":").last,
                       let url = URL(string: "evecompanion://showinfo/\(id)") {
                        result.link = url
                    } else if let url = URL(string: href) {
                        result.link = url
                    }

                    return result

                default:
                    var result = AttributedString()

                    for child in element.getChildNodes() {
                        result.append(try attributedString(from: child))
                    }

                    return result
                }
            }

            return AttributedString()
        }
    
}
