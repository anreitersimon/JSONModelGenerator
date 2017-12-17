//
//  OAS.swift
//  JSONModelGeneratorCore
//
//  Created by Simon Anreiter on 16.12.17.
//

import Foundation

public enum JSONSchemaType: String, Codable {
    case object = "object"
    case string = "string"
    case boolean = "boolean"
    case null = "null"
    case array = "array"
    case integer = "integer"
    case number = "number"
    
    /// utility to decode a single value into a set if needed
    static func decode<K>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K,
        defaultValue: Set<JSONSchemaType>
    ) throws -> Set<JSONSchemaType> {
        do {
            let singleType = try container.decode(JSONSchemaType.self, forKey: key)
            return [singleType]
        } catch DecodingError.typeMismatch {
            let multipleTypes = try container.decode([JSONSchemaType].self, forKey: key)
            return Set(multipleTypes)
        } catch DecodingError.keyNotFound {
            return defaultValue
        }
    }

}

extension Set where Element == JSONSchemaType {
    func inferredType() -> (JSONSchemaType, Bool) {
        var mutable = self
        
        let nullPresent = mutable.remove(.null) != nil
        
        guard let any = mutable.first else {
            return (.null, nullPresent)
        }
        
        return (any, nullPresent)
        
    }
}

public func decodeDictionary<K, V: Decodable>(
    _ type: V.Type,
    from container: KeyedDecodingContainer<K>,
    forKey key: K,
    lenient: Bool
) throws -> [String: V] {
    guard container.contains(key) else { return [:] }
    
    let c = try container.nestedContainer(keyedBy: _CodingKey.self, forKey: key)
    var defs: [String: V] = [:]
    
    for key in c.allKeys {
        if lenient {
            defs[key.stringValue] = try? c.decode(V.self, forKey: key)
        } else {
            defs[key.stringValue] = try c.decode(V.self, forKey: key)
        }
    }
    
    return defs
}

private struct _CodingKey: CodingKey {
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
    
    let stringValue: String
    
    var intValue: Int? {
        return nil
    }
}

public enum Reference<T: Decodable>: Decodable {
    case ref(String)
    case resolved(T)
    
    private enum CodingKeys: String, CodingKey {
        case ref = "$ref"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.ref) {
            self = .ref(try container.decode(String.self, forKey: .ref))
        } else {
            self = .resolved(try T(from: decoder))
        }
        
    }
}


public typealias PropertyReference = Reference<OASSpec.Property>


public struct OASSpec: Decodable {
    
    public let title: String?
    public let description: String?
    public let definitions: [String: Property]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.definitions = try  decodeDictionary(Property.self,
                                                 from: container,
                                                 forKey: .definitions,
                                                 lenient: decoder.leninent)
    }
    
    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case type = "type"
        case description = "description"
        case definitions = "definitions"
    }
    
    public class Property: Decodable {
        public let title: String?
        public var typeName: String?
        public let descriptor: Descriptor
        
        public indirect enum Descriptor: Decodable {
            case any(of: [PropertyReference])
            case one(of: [PropertyReference])
            case object(children: [String: PropertyReference])
            case array(of: PropertyReference)
            case string
            case boolean
            case number
            
            private enum CodingKeys: String, CodingKey {
                case anyOf
                case oneOf
                case type
                case items
                case properties
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                
                if container.contains(.anyOf) {
                    let props = try container
                        .decode([PropertyReference].self, forKey: .anyOf)
                    
                    self = .any(of: props)
                } else if container.contains(.oneOf) {
                    let props = try container
                        .decode([PropertyReference].self, forKey: .oneOf)
                    
                    self = .one(of: props)
                } else {
                    let types = try JSONSchemaType.decode(from: container, forKey: .type, defaultValue: [.object])
                
                    switch types.inferredType().0 {
                    case .array:
                        
                        let p = try container.decode(PropertyReference.self, forKey: .items)
                        self = .array(of: p)
                    case .boolean:
                        self = .boolean

                    case .object:
                        
                        let d = try decodeDictionary(PropertyReference.self, from: container, forKey: .properties, lenient: decoder.leninent)
                        
                        self = .object(children: d)
                    case .string:
                        self = .string
                    case .integer:
                        self = .number
//                         throw DecodingError.dataCorruptedError(forKey: .items, in: container, debugDescription: "integer not allowed")
                    case .number:
                        self = .number
                    default:
                    throw DecodingError.dataCorruptedError(forKey: .items, in: container, debugDescription: "null not allowed")

                    }
                    
                }
            }
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.title = try container.decodeIfPresent(String.self, forKey: .title)
            self.descriptor = try Descriptor(from: decoder)
        }
        
        private enum CodingKeys: String, CodingKey {
            case title = "title"
            case type = "type"
            case description = "description"
        }
    }
}
