//
//  SDEConverter.swift
//  SDEConverter
//
//  Created by Jonas Schlabertz on 13.10.25.
//

import ArgumentParser
import SQLite
import Foundation

@main
struct SDEConverter: ParsableCommand {
    
    @Option var sdeDir: String
    @Option var effectPatches: String
    @Option var outputFile: String
    
    mutating func run() throws {
        print(shell("sed -i -e 's/: 6E-578/: \"6E-578\"/g' ./\(sdeDir)/mapSolarSystems.yaml"))
        print("Converting SDE data from \(sdeDir) to \(outputFile)")
        
        let builder = try SDEBuilder(sdeDir: sdeDir,
                                     effectPatches: effectPatches,
                                     outputFile: outputFile)
        try builder.run()
    }
    
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
}
