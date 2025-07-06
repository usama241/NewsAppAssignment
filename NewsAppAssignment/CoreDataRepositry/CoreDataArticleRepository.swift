import Foundation
import CoreData

protocol ArticleRepository {
    func save(articles: [ArticleModel])
    func getCachedArticles() -> [ArticleModel]
    func clearExpiredArticles()
}
class CoreDataArticleRepository: ArticleRepository {
    private let context = CoreDataStack.shared.context
    
    private var memoryCache: [ArticleModel] = []
    
    func save(articles: [ArticleModel]) {
        clearAllArticles()
        memoryCache = articles

        let now = Date()
        let expiry = Calendar.current.date(byAdding: .minute, value: 5, to: now)!
        
        for article in articles {
            let entity = ArticleEntity(context: context)
            entity.title = article.title
            entity.source = article.source
            entity.imageUrl = article.urlToImage
            entity.url = article.url
            entity.fetchedAt = now
            entity.expiresAt = expiry
        }
        
        do {
            try context.save()
        } catch {
            debugPrint("Failed to save articles: \(error)")
        }
    }

    func getCachedArticles() -> [ArticleModel] {
        if !memoryCache.isEmpty {
            return memoryCache
        }

        let fetch: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        let now = Date()
        fetch.predicate = NSPredicate(format: "expiresAt > %@", now as NSDate)

        do {
            let entities = try context.fetch(fetch)
            let articles = entities.map { articleEntity in
                return ArticleModel(
                    source: articleEntity.source,
                    title: articleEntity.title,
                    url: articleEntity.url,
                    urlToImage: articleEntity.imageUrl
                )
            }
            
            memoryCache = articles
            return articles
        } catch {
            debugPrint("Failed to fetch cached articles: \(error)")
            return []
        }
    }

    func clearExpiredArticles() {
        let fetch: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        let now = Date()
        fetch.predicate = NSPredicate(format: "expiresAt <= %@", now as NSDate)

        do {
            let expired = try context.fetch(fetch)
            for entity in expired {
                context.delete(entity)
            }
            try context.save()
            memoryCache.removeAll { article in
                expired.contains { $0.url == article.url }
            }
        } catch {
            debugPrint("Failed to clear expired articles: \(error)")
        }
    }
    
    private func clearAllArticles() {
        let fetch: NSFetchRequest<NSFetchRequestResult> = ArticleEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try context.execute(deleteRequest)
            memoryCache.removeAll()
        } catch {
            debugPrint("Failed to delete all articles: \(error)")
        }
    }
}
