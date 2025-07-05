//
//  CoreDataArticleRepository.swift
//  NewsAppAssignment
//
//  Created by MacBook Pro on 05/07/2025.
//

import Foundation
import CoreData

protocol ArticleRepository {
    func save(articles: [ArticleModel])
    func getCachedArticles() -> [ArticleModel]
    func clearExpiredArticles()
}

class CoreDataArticleRepository: ArticleRepository {
    private let context = CoreDataStack.shared.context
    
    func save(articles: [ArticleModel]) {
        clearAllArticles()
        let now = Date()
        let expiry = Calendar.current.date(byAdding: .minute, value: 1, to: now)!
        
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
            print("Failed to save articles: \(error)")
        }
    }

    func getCachedArticles() -> [ArticleModel] {
        let fetch: NSFetchRequest<ArticleEntity> = ArticleEntity.fetchRequest()
        let now = Date()
        fetch.predicate = NSPredicate(format: "expiresAt > %@", now as NSDate)

        do {
            let entities = try context.fetch(fetch)
            return entities.map { articleEntity in
                return ArticleModel(
                    source: articleEntity.source,
                    author: nil,
                    title: articleEntity.title,
                    description: nil,
                    url: articleEntity.url,
                    urlToImage: articleEntity.imageUrl,
                    publishedAt: nil,
                    content: nil
                )
            }
        } catch {
            print("Failed to fetch cached articles: \(error)")
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
        } catch {
            print("Failed to clear expired articles: \(error)")
        }
    }

    
    private func clearAllArticles() {
        let fetch: NSFetchRequest<NSFetchRequestResult> = ArticleEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Failed to delete all articles: \(error)")
        }
    }
}
