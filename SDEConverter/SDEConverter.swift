//
//  SDEConverter.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 13.10.25.
//

import Foundation
import ArgumentParser
import SQLite

@main
struct SDEConverter: ParsableCommand {
    
    @Option var sdeDir: String
    @Option var effectPatches: String
    @Option var outputFile: String
    
    mutating func run() throws {
        print("Converting SDE data from \(sdeDir) to \(outputFile)")
        
        let builder = try SDEBuilder(sdeDir: sdeDir,
                                     effectPatches: effectPatches,
                                     outputFile: outputFile)
        try builder.run()
    }
    
}
