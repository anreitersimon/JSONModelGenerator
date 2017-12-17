//
//  Property+Generate.swift
//  JSONModelGeneratorPackageDescription
//
//  Created by Simon Anreiter on 16.12.17.
//

import Foundation

public typealias GeneratorOutput = [String]

public protocol Generating {
    func render() -> [String]
}


// indent operator
prefix operator ==>

prefix func ==> (val: String) -> String {
    return "\t\(val)"
}

prefix func ==> (val: [String]) -> [String] {
    return val.map(==>)
}
