import Foundation
import JSONModelGeneratorCore
import Basic
import Utility

do {

    let args = Array(CommandLine.arguments.dropFirst())
    
    let command = try GenerateFromOASModelsCommand(commandLineArgs: args)
    
    try command.run()
    
    
} catch {
    
    print("Whoops! An error occurred: \(error)")
}
