import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct SimpleDiagnosticMessage: DiagnosticMessage, Error {
  let message: String
  let diagnosticID: MessageID
  let severity: DiagnosticSeverity
}

extension SimpleDiagnosticMessage: FixItMessage {
  var fixItID: MessageID { diagnosticID }
}

public struct NetworkRequestMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let messageID = MessageID(domain: "NetworkRequestMacro", id: "Not a struct")
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: SimpleDiagnosticMessage(
                    message: "Replace \(declaration.self.kind) with struct",
                    diagnosticID: messageID,
                    severity: .error
                )
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let inheritanceClause = structDecl.inheritanceClause?.as(TypeInheritanceClauseSyntax.self)
        
        let inheritedTypeCollection = inheritanceClause?.inheritedTypeCollection.as(InheritedTypeListSyntax.self)
        
        guard let type = inheritedTypeCollection?.first?.as(InheritedTypeSyntax.self) else {
            let messageID = MessageID(domain: "NetworkRequestMacro", id: "Not Codable conformance")
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: SimpleDiagnosticMessage(
                    message: "Struct does not conform to Codable",
                    diagnosticID: messageID,
                    severity: .error
                )
            )
            context.diagnose(diagnostic)
            return []
        }
        
        if (type.typeName.description != "Codable ") {
            let messageID = MessageID(domain: "NetworkRequestMacro", id: "Not Codable conformance")
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: SimpleDiagnosticMessage(
                    message: "Struct does not conform to Codable",
                    diagnosticID: messageID,
                    severity: .error
                ),
                fixIts: [
                    FixIt(
                        message: SimpleDiagnosticMessage(
                            message: "Add Codable conformance",
                            diagnosticID: messageID,
                            severity: .error
                        ),
                        changes: [
                            FixIt.Change.replace(
                                oldNode: Syntax(type),
                                newNode: Syntax(InheritedTypeSyntax(typeName: TypeSyntax(stringLiteral: "Codable")))
                            )
                        ]
                    ),
                ]
            )
            context.diagnose(diagnostic)
            return []
        }

        
        let structIdentifier = structDecl.identifier
        
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
