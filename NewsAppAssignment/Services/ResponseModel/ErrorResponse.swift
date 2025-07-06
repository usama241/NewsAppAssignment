import Foundation

struct ErrorResponse: Codable {
    let responseCode: String?
    let responseMessage: String?
    let traceId: String?
    let body: [String]?

    enum CodingKeys: String, CodingKey {
        case responseCode = "responseCode"
        case responseMessage = "responseMessage"
        case traceId = "traceId"
        case body = "body"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseCode = try? container.decodeIfPresent(String.self, forKey: .responseCode)
        responseMessage = try? container.decodeIfPresent(String.self, forKey: .responseMessage)
        traceId = try? container.decodeIfPresent(String.self, forKey: .traceId)
        body = try? container.decodeIfPresent([String].self, forKey: .body) ?? []
    }
}
