//
//  JSONReferenceResolver.swift
//  mobilecity
//
//  Created by Simon Anreiter on 18.11.17.
//  Copyright © 2017 Swift Management AG. All rights reserved.
//

import Foundation

/** Allows usage of JSON-Pointers in when wrapping objects in `ReferenceResolved` while decoding

 - example:
 
*/
class JSONReferenceResolver: ReferenceResolverProtocol {
    
    let decoder: JSONDecoder
    var jsonProvider: (String) -> Data?
    
    init(decoder: JSONDecoder, jsonProvider: @escaping (String) -> Data?) {
        self.decoder = decoder
        self.jsonProvider = jsonProvider
    }
    
    func decode<T>(_ type: T.Type, for reference: String) throws -> T where T: Decodable {
        guard let data = self.jsonProvider(reference) else {
            let context = DecodingError.Context(
                codingPath: [],
                debugDescription: "No JSON provided for ref \(reference)"
            )
            
            throw DecodingError.dataCorrupted(context)
        }
        
        return try self.decoder.decode(type, from: data)
    }
}
