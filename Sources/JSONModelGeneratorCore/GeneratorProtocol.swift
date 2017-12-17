//
//  GeneratorProtocol.swift
//  JSONModelGeneratorPackageDescription
//
//  Created by Simon Anreiter on 17.12.17.
//

import Foundation

public protocol GeneratorProtocol {
    associatedtype Input
    associatedtype Output
    
    func genertate(_ input: Input) -> Output
}
