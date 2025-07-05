import Foundation

class NewsViewModel: ObservableObject {
    @Published var articles: [ArticleModel] = []
    private let apiService: NewsAPIService
    private let repository: ArticleRepository
    
    init(apiService: NewsAPIService, repository: ArticleRepository) {
        self.apiService = apiService
        self.repository = repository
    }
    
    func loadArticles(forceRefresh: Bool = false) {
        if forceRefresh {
            fetchAndCache()
            return
        }

        repository.clearExpiredArticles()
        let cached = repository.getCachedArticles()
        
        if !cached.isEmpty {
            self.articles = cached
        } else {
            fetchAndCache()
        }
    }
    
    private func fetchAndCache() {
        Task { [weak self] in
            do {
                let articles = try await self?.apiService.newsList() ?? []
                DispatchQueue.main.async {
                    self?.articles = articles
                    self?.repository.save(articles: articles)
                }
            } catch {
                print("API error: \(error)")
            }
        }
    }

}
