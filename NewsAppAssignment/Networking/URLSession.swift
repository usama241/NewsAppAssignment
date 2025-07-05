import Foundation
// MARK: - Protocols
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

protocol APIClientProtocol {
    init(urlSession: URLSessionProtocol)
    func sendRequest<T: Decodable>(_ router: APIRouter) async throws -> APIResponse<T>
}
