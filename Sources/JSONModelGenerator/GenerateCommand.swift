//
//  GenerateCommand.swift
//  JSONModelGeneratorPackageDescription
//
//  Created by Simon Anreiter on 16.12.17.
//

import Foundation
import Basic
import Utility
import JSONModelGeneratorCore

public protocol Command {
    init(commandLineArgs: [String]) throws
    
    func run() throws
}

public class GenerateFromOASModelsCommand: Command {
    
    let file: AbsolutePath
    let outputDirecory: AbsolutePath
    let lenient: Bool
    

    required public init(
        file: AbsolutePath,
        outputDirecory: AbsolutePath,
        lenient: Bool
    ) {
        self.file = file
        self.outputDirecory = outputDirecory
        self.lenient = lenient
    }
    
    public func run() throws {
        let progressBar = createProgressBar(
            forStream: stdoutStream,
            header: "Generating models \(file.relative(to: currentWorkingDirectory ).asString)"
        )

        let generator = try OASModelGenerator(
            file: file,
            lenient: lenient
        )

        let tc = ( stdoutStream as? LocalFileOutputByteStream)
            .flatMap { TerminalController(stream: $0) }

        generator.generate { (percent, key, p) in
            progressBar.update(percent: percent, text: key)
        }

        progressBar.complete()
    }
    
    public required convenience init(commandLineArgs: [String]) throws{
        
        let parser = ArgumentParser(
            usage: "generate-models",
            overview: "Generates Swift-Models from JSON-Schema"
        )

        let fileArg = parser.add(
            option: "--file",
            shortName: "-f",
            kind: PathArgument.self,
            usage: "path to oas-specification json",
            completion: .filename
        )
        
        let outputDirArg = parser.add(
            option: "--output-directory",
            shortName: "-o",
            kind: PathArgument.self,
            usage: "output directory",
            completion: .filename
        )
        
        let lenientArg = parser.add(
            option: "--lenient",
            shortName: "-l",
            kind: Bool.self,
            usage: "Continue after encountering Parsing Errors",
            completion: .unspecified
        )
        
        let results = try parser.parse(commandLineArgs)
        
        guard let file = results.get(fileArg)?.path else {
            throw ArgumentParserError.expectedArguments(parser, ["file"])
        }
        
    
        let outputDir = results.get(outputDirArg)?.path ?? AbsolutePath("models", relativeTo: currentWorkingDirectory)

        self.init(
            file: file,
            outputDirecory: outputDir,
            lenient: results.get(lenientArg) ?? false
        )
        
    }
    
}
