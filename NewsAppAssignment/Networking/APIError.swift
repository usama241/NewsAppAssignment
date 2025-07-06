import Foundation

enum APIError: LocalizedError {
    case jsonParsing
    case notFound
    case unexpectedError
    case noInternet
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case .jsonParsing:
            return "Invalid response. Please try again later."
        case .notFound:
            return "Not found"
        case .unexpectedError:
            return "We are unable to process your request at this time. Please try again later."
        case .noInternet:
            return "Please ensure your device is connected to the internet and try again."
        case .other(let message):
            return message
        }
    }
}
