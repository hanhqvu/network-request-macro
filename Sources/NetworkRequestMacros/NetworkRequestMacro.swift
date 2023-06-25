import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum NetworkRequestMacroError: Error, CustomStringConvertible {
    case notStruct
    case noConformance
    case notCodable
    
    var description: String {
        switch self {
        case .notStruct:
            return "Declaration need to be a struct"
        case .noConformance:
            return "Struct has no conformance"
        case .notCodable:
            return "Struct does not conform to Codable protocol"
        }
    }
}

public struct NetworkRequestMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let strucDecl = declaration.as(StructDeclSyntax.self) else {
            throw NetworkRequestMacroError.notStruct
        }
        
        let inheritanceClause = strucDecl.inheritanceClause?.as(TypeInheritanceClauseSyntax.self)
        
        let inheritedTypeCollection = inheritanceClause?.inheritedTypeCollection.as(InheritedTypeListSyntax.self)
        
        let conformance = inheritedTypeCollection?.first?.typeName
        
        let name = conformance?.description
        
        guard let name = name else {
            throw NetworkRequestMacroError.noConformance
        }
        
        if (name != "Codable ") {
            throw NetworkRequestMacroError.notCodable
        }
        
        let structIdentifier = strucDecl.identifier
        
        return [
            """
            func getRequest() async throws -> \(raw: structIdentifier) {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api/get")!)
                
                do {
                    let decoder = JSONDecoder()
                    let res = try decoder.decode(\(raw: structIdentifier).self, from: data)
                    return res
                } catch {
                    throw NetworkError.invalidData
                }
            }
            """
        ]
    }
}

@main
struct NetworkRequestPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        NetworkRequestMacro.self,
    ]
}
