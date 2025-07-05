import Foundation

// MARK: - APIResponse
struct APIResponse<T: Decodable> {
    let httpStatusCode: Int
    let result: T
}

// MARK: - URLSession Conformance
extension URLSession: URLSessionProtocol {}

// MARK: - APIClient Implementation
struct APIClient: APIClientProtocol {
    let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }

    func sendRequest<T: Decodable>(_ router: APIRouter) async throws -> APIResponse<T> {
        var dataResponse: (Data, URLResponse)!

        do {
            guard let request = self.makeURLRequest(router: router) else {
                throw APIError.other("Bad request")
            }
            dataResponse = try await urlSession.data(for: request)
        } catch {
            if let error = error as NSError?,
               error.domain == NSURLErrorDomain,
               error.code == NSURLErrorNotConnectedToInternet {
                throw APIError.noInternet
            } else {
                throw APIError.unexpectedError
            }
        }

        do {
            guard let httpResponse = dataResponse.1 as? HTTPURLResponse else {
                throw APIError.unexpectedError
            }

            let data = dataResponse.0

            switch httpResponse.statusCode {
            case 200...210:
                if httpResponse.statusCode == 203,
                   let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.other(errorResponse.responseMessage ?? errorResponse.body?.first ?? APIError.unexpectedError.localizedDescription)
                }

                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    return APIResponse(httpStatusCode: httpResponse.statusCode, result: result)
                } catch {
                    print("Decoding error:", error.localizedDescription)
                    throw APIError.jsonParsing
                }

            case 404:
                throw APIError.notFound

            default:
                throw APIError.other("Something went wrong")
            }

        } catch {
            throw error
        }
    }

    // MARK: - Private: Make URLRequest
    private func makeURLRequest(router: APIRouter) -> URLRequest? {
        guard var urlComponent = URLComponents(string: router.baseURL) else {
            return nil
        }

        // Append path
        urlComponent.path.append(router.path)

        let parameters = router.parameters
        var urlRequest: URLRequest?

        switch router.method {
        case .get:
            var queryItems: [URLQueryItem] = []
            for (key, value) in parameters {
                queryItems.append(URLQueryItem(name: key, value: (value as! String)))
            }
            urlComponent.queryItems = queryItems

            guard let url = urlComponent.url else {
                return nil
            }
            urlRequest = URLRequest(url: url)

        case .post:
            guard let url = urlComponent.url else {
                return nil
            }
            urlRequest = URLRequest(url: url)

            if let body = try? JSONSerialization.data(withJSONObject: router) {
                urlRequest?.httpBody = body
                print("Request Body:", String(data: body, encoding: .utf8) ?? "")
            }
        }

        // HTTP Method
        urlRequest?.httpMethod = router.method.rawValue

        // Headers
        for (key, value) in router.headers {
            urlRequest?.setValue(value, forHTTPHeaderField: key)
        }

        print("Final URL:", urlRequest?.url ?? "")
        return urlRequest
    }
}
