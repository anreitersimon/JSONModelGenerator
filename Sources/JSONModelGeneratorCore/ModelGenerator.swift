import Foundation
import Basic
import Utility

extension String {
    func asTypeName() -> String {
        return self.camelCased.upperFirst
    }
    

    var camelCased: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.upperFirst }
            .joined()
            .lowerFirst
    }

    var upperFirst: String {
        let range = self.startIndex..<self.index(after: self.startIndex)
        var m = self
        
        m.replaceSubrange(range, with: self[range].uppercased())
        
        return m
    }
    
    var lowerFirst: String {
        let range = self.startIndex..<self.index(after: self.startIndex)
        var m = self
        
        m.replaceSubrange(range, with: self[range].lowercased())
        
        return m
    }
}


public protocol Product {
    func declare(name: String) -> [String]
    func manifest() -> [String]
}

public final class OASModelGenerator {
    struct Context {
        var files: [String: [String]]
    }
    
    public typealias ProgressCallBack = (
        _ percent: Int,
        _ spec: String,
        _ definition: OASSpec.Property
    ) -> Void
    
    let spec: OASSpec
    
    public init(spec: OASSpec) throws {
        self.spec = spec
    }
    
    public init(file: AbsolutePath, lenient: Bool) throws {
        let url = URL(fileURLWithPath: file.asString)
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        decoder.leninent = lenient
        
        self.spec = try decoder.decode(OASSpec.self, from: data)
    }
    
    public func generate(progressCallback: ProgressCallBack = { _,_,_ in }) {
        let count = self.spec.definitions.count
        
        var processed = 1
        
        var context = Context(files: [:])
        
        for (key,value) in self.spec.definitions {
            let percent = Int(ceil(Double(processed) / Double(count) * 100.0))
            
            context = self.generate(
                typeName: key,
                value: value,
                context: context
            )

            progressCallback(percent, key, value)
            
            processed += 1
        }
        
        let lines = Array(context.files.values)
            .flatMap { $0 }
            .joined(separator: "\n")
        
        print(lines)
    }
    
    func resolve(_ reference: PropertyReference, parentName: String?) -> (typeName: String, property: OASSpec.Property)? {
        switch reference {
        case .ref(let name):return self.spec.definitions[name].map { (name.asTypeName(), $0) }
        case .resolved(let ref):
            switch ref.descriptor {
            case .any(let of): return parentName.map { ("Any\($0.upperFirst)", ref) }
            case .array(let of): return nil
            case .boolean: return ("Bool", ref)
            case .number: return ("Double", ref)
            case .object(let children): return parentName.map { ($0, ref) }
            case .one(let of): return nil
            case .string: return ("String", ref)
                
            }
        }
    }
    
    /// top-level property
    func generate(
        typeName: String,
        value: OASSpec.Property,
        context: Context
    ) -> Context {
        
        var context = context
        
        guard !context.files.keys.contains(typeName) else { return context }
        
        switch value.descriptor {
        case .any(let of):
            return of.reduce(context) { (ctx, ref) in
                guard let (t, p) = self.resolve(ref, parentName: nil) else { return ctx }
                
                return self.generate(
                    typeName: t,
                    value: p,
                    context: ctx
                )
                    
            }
            
        case .object(let children):

            context.files[typeName]  = self.manifest(typeName: typeName, value: value)
            
            children.forEach { (key, childRef) in
                
                
                guard let (childTypeName, property) = self.resolve(childRef, parentName: key) else { return }
                
                switch childRef {
                case .ref:
                    context = self.generate(
                        typeName: childTypeName,
                        value: property,
                        context: context
                    )
                case .resolved:
                    return
                }
                
                

                
            }
            
            return context
            
        case .array(let of):
            
            guard let (t, p) = self.resolve(of, parentName: nil) else { return context }
            
            context = self.generate(
                typeName: t,
                value: p,
                context: context
            )
            
            return context
            
        case .boolean: return context
        case .number: return context
        case .one(let of): return context
        case .string: return context
        }
    }

    func manifest(
        typeName: String,
        value: OASSpec.Property
    ) -> [String] {
        
        switch value.descriptor {
        case .any(let of):
            return []
            
        case .object(let children):
            
            return self.structDecl(typeName.asTypeName()) {
                let nestedTypeDeclarations = children
                    .flatMap { (key,childRef) -> [String] in
                        guard let (childTypeName, property) = self.resolve(childRef, parentName: key) else { return [] }
                        
                        switch childRef {
                        case .resolved(let resolved):
                            return self.manifest(
                                typeName: childTypeName.asTypeName(),
                                value: resolved
                            )
                        case .ref:
                            return []
                        }
                    }
                
                
                let variableDeclarations = children.flatMap { (key,childRef) -> [String] in
                    
                    guard let (childTypeName, _) = self.resolve(childRef, parentName: key) else { return [] }
                    
                    return self.variableDecl(key, type: childTypeName.asTypeName()).flatMap { $0 }
                }
                
                return [nestedTypeDeclarations, variableDeclarations].flatMap { $0 }
            }

        case .array(let of): return []
        case .boolean: return []
        case .number: return []
        case .one(let of): return []
        case .string: return []
        }
        
    }
    
    
    func structDecl(_ name: String, body: () -> [String]) -> [String] {
        return [
            ["struct \(name) {"],
            ==>body(),
            ["}"]
        ].flatMap { $0 }
    }
    

    
    func variableDecl(_ name: String, type: String) -> [String] {
        return ["let \(name): \(type)"]
    }
    
    
}
