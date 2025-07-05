import Foundation
import UIKit

class NewsListCoordinator {
    
    let viewControllerFactory: ViewControllerFactory
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController, viewControllerFactory: ViewControllerFactory) {
        self.navigationController = navigationController
        self.viewControllerFactory = viewControllerFactory
    }

}
