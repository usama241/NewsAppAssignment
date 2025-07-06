import Foundation

protocol NewsAPIServiceProtocol {
    
    init(apiClient: APIClientProtocol)
    
    func newsList(source: String, apiKey: String) async throws -> [ArticleModel]
}

class NewsAPIService: NewsAPIServiceProtocol {
    let apiClient: APIClientProtocol
    
    required init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func newsList(source: String, apiKey: String) async throws -> [ArticleModel] {
        let router = APIRouter.newsList(source: source, apiKey: apiKey)
        let response: APIResponse<NewsResponse> = try await apiClient.sendRequest(router)
        let apiResponse = response.result
        if apiResponse.status == "ok" {
            let fetchedNewsList = apiResponse.articles ?? []
            return fetchedNewsList.map { news in
                ArticleModel(source: news.source?.name,
                             title: news.title,
                             url: news.url,
                             urlToImage: news.urlToImage
                )
            }
        }
        throw APIError.other("Unable to process at the moment.")
    }
    
    
}
