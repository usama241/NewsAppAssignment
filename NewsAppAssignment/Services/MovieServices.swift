import Foundation

protocol MovieServicesProtocol {
    
    init(apiClient: APIClientProtocol)
    
    func newsList() async throws -> [ArticleModel]
}

class MovieServices: MovieServicesProtocol {
    let apiClient: APIClientProtocol
    
    required init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func newsList() async throws -> [ArticleModel] {
         let router = APIRouter.newsList(source: "bbc-news", apiKey: "1a51c99ade634d3a9d2c6b1464bf585d")
         let response: APIResponse<NewsResponse> = try await apiClient.sendRequest(router)
         let apiResponse = response.result
         if apiResponse.status == "ok" {
             let fetchedNewsList = apiResponse.articles ?? []
             return fetchedNewsList.map { news in
                 ArticleModel(source: news.source,
                              author: news.author,
                              title: news.title,
                              description: news.description,
                              url: news.url,
                              urlToImage: news.urlToImage,
                              publishedAt: news.publishedAt,
                              content: news.content)
             }
         }
        throw APIError.other("Unable to process at the moment.")
     }

    
}
