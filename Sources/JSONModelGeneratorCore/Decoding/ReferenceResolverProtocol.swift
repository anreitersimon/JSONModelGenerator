//
//  Decoder+References.swift
//  mobilecity
//
//  Created by Simon Anreiter on 17.11.17.
//  Copyright © 2017 Swift Management AG. All rights reserved.
//

import Foundation

protocol ReferenceResolverProtocol {
    func decode<T: Decodable>(_ type: T.Type, for reference: String) throws -> T
}

extension CodingUserInfoKey {
    static var referenceResolver: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "referenceResolver")!
    }
    
    static var leninent: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "leninent")!
    }
}

extension JSONDecoder {
    var referenceResolver: ReferenceResolverProtocol? {
        get {
            return self.userInfo[.referenceResolver] as? ReferenceResolverProtocol
        }
        set {
            self.userInfo[.referenceResolver] = newValue
        }
    }
    
    
    var leninent: Bool {
        get {
            return (self.userInfo[.leninent] as? Bool) ?? false
        }
        set {
            self.userInfo[.leninent] = newValue
        }
    }
}

extension Decoder {
    var referenceResolver: ReferenceResolverProtocol? {
        return self.userInfo[.referenceResolver] as? ReferenceResolverProtocol
    }

    var leninent: Bool {
        return (self.userInfo[.leninent] as? Bool) ?? false
    }
}
