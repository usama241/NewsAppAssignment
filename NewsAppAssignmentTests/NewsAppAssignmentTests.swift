
import XCTest
import Testing
import CoreData
@testable import NewsAppAssignment

class CoreDataArticleRepositoryTests: XCTestCase {
    
    var repository: CoreDataArticleRepository!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        let coreDataStack = CoreDataStack.shared
        context = coreDataStack.context
        repository = CoreDataArticleRepository()
    }
    
    override func tearDown() {
        super.tearDown()
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        if let articles = try? context.fetch(fetchRequest) {
            for article in articles {
                context.delete(article)
            }
        }
        try? context.save()
    }
    
    // Test CacheManager logic
    func testSaveAndRetrieveArticles() {
        let articlesToSave = [
            ArticleModel(source: "Source1", title: "Title1", url: "https://url1.com", urlToImage: "https://image1.com"),
            ArticleModel(source: "Source2", title: "Title2", url: "https://url2.com", urlToImage: "https://image2.com")
        ]
        
        repository.save(articles: articlesToSave)
        let cachedArticles = repository.getCachedArticles()
        XCTAssertEqual(cachedArticles.count, articlesToSave.count)
        XCTAssertEqual(cachedArticles[0].title, articlesToSave[0].title)
        XCTAssertEqual(cachedArticles[1].source, articlesToSave[1].source)
    }
    
    // Test Expiry detection
    func testExpiredArticlesAreRemoved() {
        let now = Date()
        let expiredArticle = ArticleModel(source: "Source1", title: "Expired Article", url: "https://expired.com", urlToImage: "https://expired.com/image")
        
        let expiredEntity = ArticleEntity(context: context)
        expiredEntity.title = expiredArticle.title
        expiredEntity.source = expiredArticle.source
        expiredEntity.url = expiredArticle.url
        expiredEntity.imageUrl = expiredArticle.urlToImage
        expiredEntity.fetchedAt = now.addingTimeInterval(-300)
        expiredEntity.expiresAt = now.addingTimeInterval(-150)
        try? context.save()
        repository.clearExpiredArticles()
        let fetchRequest: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        let remainingArticles = try? context.fetch(fetchRequest)
        XCTAssertEqual(remainingArticles?.count, 0)
    }
    
    func testManualInvalidationClearsCache() {
        let articlesToSave = [
            ArticleModel(source: "Source1", title: "Title1", url: "https://url1.com", urlToImage: "https://image1.com"),
            ArticleModel(source: "Source2", title: "Title2", url: "https://url2.com", urlToImage: "https://image2.com")
        ]
        
        repository.save(articles: articlesToSave)
        var cachedArticles = repository.getCachedArticles()
        XCTAssertEqual(cachedArticles.count, articlesToSave.count)
        repository.clearAllArticles()
        cachedArticles = repository.getCachedArticles()
        XCTAssertEqual(cachedArticles.count, 0)
    }
}
