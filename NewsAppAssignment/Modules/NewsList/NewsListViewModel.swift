import Foundation

class NewsListViewModel {
    
    let service: MovieServices!
    @Published var newsList: [ArticleModel]?
 
    //MARK: - Init
    init(service: MovieServices) {
        self.service = service
    }
}

extension NewsListViewModel {
    
    func newsList() async throws {
            let response  = try await service.newsList()
            print(response)
            self.newsList = response
    }
}

