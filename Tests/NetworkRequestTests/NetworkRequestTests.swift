import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import NetworkRequestMacros
import SwiftDiagnostics

let testMacros: [String: Macro.Type] = [
    "NetworkRequest": NetworkRequestMacro.self,
]

final class NetworkRequestTests: XCTestCase {
    func testMacro() {
        assertMacroExpansion(
            """
            @NetworkRequest
            struct NetworkResponse: Codable {
                let id: String
            }
            """,
            expandedSource: """
            struct NetworkResponse: Codable {
                let id: String
            }
            func getRequest() async throws -> NetworkResponse {
                let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api/get")!)
            
                do {
                    let decoder = JSONDecoder()
                    let res = try decoder.decode(NetworkResponse.self, from: data)
                    return res
                } catch {
                    throw NetworkError.invalidData
                }
            }
            """,
            macros: testMacros
        )
    }
    func testMacroOnEnum() {
        assertMacroExpansion(
            """
            @NetworkRequest
            enum NetworkResponse: Error {
                case error
            }
            """,
            expandedSource: """
            enum NetworkResponse: Error {
                case error
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Replace enumDecl with struct", line: 1, column: 1),
            ],
            macros: testMacros
        )
    }
    func testMacroNoConformance() {
        assertMacroExpansion(
            """
            @NetworkRequest
            struct NetworkResponse {
                let id: String
            }
            """,
            expandedSource: """
            struct NetworkResponse {
                let id: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Struct does not conform to Codable", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    func testMacroNoCodable() {
        assertMacroExpansion(
            """
            @NetworkRequest
            struct NetworkResponse: View {
                let id: String
            }
            """,
            expandedSource: """
            struct NetworkResponse: View {
                let id: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Struct does not conform to Codable", line: 1, column: 1, fixIts: [
                    FixItSpec(message: "Add Codable conformance")
                ])
            ],
            macros: testMacros
        )
    }
}
