import Foundation

class NewsViewModel: ObservableObject {
    @Published var articles: [ArticleModel] = []
    private let apiService: NewsAPIService
    private let repository: ArticleRepository
    
    init(apiService: NewsAPIService, repository: ArticleRepository) {
        self.apiService = apiService
        self.repository = repository
    }
    
    func loadArticles(forceRefresh: Bool) {
        if forceRefresh {
            fetchAndCache()
            return
        }

        repository.clearExpiredArticles()
        let cached = repository.getCachedArticles()
        print(cached)
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
                    print(articles)
                    self?.articles = articles
                    self?.repository.save(articles: articles)
                }
            } catch {
                print("API error: \(error)")
            }
        }
    }
}
