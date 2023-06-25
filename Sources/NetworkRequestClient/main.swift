import NetworkRequest
import Foundation

enum NetworkError: Error, CustomStringConvertible {
    case invalidData
    
    var description: String {
        switch self {
        case .invalidData:
            return "Invalid Data"
        }
    }
}

@NetworkRequest
struct NetworkResponse: Codable {
    let id: String
}
