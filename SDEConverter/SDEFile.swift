//
//  SDEFile.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 14.10.25.
//

import Foundation
import Yams

enum SDEFile {
    
    case types
    case typeDogma
    case attributes
    
    private var fileName: String {
        switch self {
        case .types:
            return "types.yaml"
        case .attributes:
            return "dogmaAttributes.yaml"
        case .typeDogma:
            return "typeDogma.yaml"
        }
    }
    
    func loadFile(sdeDir: String) throws -> [String: [String: Any]] {
        let fileContentString = try loadFileContent(sdeDir: sdeDir)
        print("Parsing yaml for file \(fileName)")
        
        let decodedFileContent = try Yams.load(yaml: fileContentString)
        
        guard let decodedFileContent = decodedFileContent as? [String: [String: Any]] else {
            print("Cannot read file content of file \(fileName) as expected")
            fatalError()
        }
        
        return decodedFileContent
    }
    
    private func loadFileContent(sdeDir: String) throws -> String {
        print("Loading \(fileName)")
        return try String(contentsOfFile: "\(sdeDir)/\(fileName)", encoding: .utf8)
    }
    
}
