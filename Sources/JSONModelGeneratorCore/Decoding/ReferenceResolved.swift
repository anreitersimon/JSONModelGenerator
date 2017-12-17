//
//  ReferenceResolved.swift
//  mobilecity
//
//  Created by Simon Anreiter on 18.11.17.
//  Copyright © 2017 Swift Management AG. All rights reserved.
//

import Foundation

struct ReferenceResolved<T: Decodable>: Decodable {
    let ref: T
    
    private enum CodingKeys: String, CodingKey {
        case ref = "$ref"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let ref = try container.decodeIfPresent(String.self, forKey: .ref) else {
            self.ref = try T.init(from: decoder)
            return
        }
        
        guard let resolver = decoder.referenceResolver else {
            
            let context = DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "no reference resolver for \(ref)"
            )
            
            throw DecodingError.dataCorrupted(context)
            
        }
        
        self.ref = try resolver.decode(T.self, for: ref)
    }
}
