import Foundation
import UIKit

class AppCoordinator {
    
    let window: UIWindow
    let viewControllerFactory: ViewControllerFactoryProtocol
    private var navigationController: UINavigationController!

    init(window: UIWindow, viewControllerFactory: ViewControllerFactoryProtocol) {
        self.window = window
        self.viewControllerFactory = viewControllerFactory
    }
    
    func start() {
        startApp()
    }
}

extension AppCoordinator {
    fileprivate func startApp() {
        navigationController = UINavigationController()
        let viewController = viewControllerFactory.newsListViewController(navigationController: navigationController)
        navigationController.pushViewController(viewController, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
