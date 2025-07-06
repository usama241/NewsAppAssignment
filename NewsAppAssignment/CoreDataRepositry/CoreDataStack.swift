import Foundation
import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack()
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NewsAppAssignment")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data stack init failed: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}
