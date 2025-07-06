import Foundation

class NewsViewModel: ObservableObject {
    
    @Published var articles: [ArticleModel] = []
    private let apiService: NewsAPIService
    private let repository: ArticleRepository
    let source: String = "bbc-news"
    let apiKey: String = "1a51c99ade634d3a9d2c6b1464bf585d"
    
    init(apiService: NewsAPIService, repository: ArticleRepository) {
        self.apiService = apiService
        self.repository = repository
    }
    
    func loadArticles(forceRefresh: Bool) async throws {
        if forceRefresh {
            self.articles = try await fetchAndCache()
            return
        }
        
        let cached = repository.getCachedArticles()
        
        if !cached.isEmpty {
            self.articles = cached
        } else {
            self.articles = try await fetchAndCache()
        }
        repository.clearExpiredArticles()
    }
    
    func fetchAndCache() async throws -> [ArticleModel] {
        do {
            let articles = try await apiService.newsList(source: self.source, apiKey: self.apiKey)
            repository.save(articles: articles)
            self.articles = articles
            return articles
        } catch {
            throw error
        }
    }
}
