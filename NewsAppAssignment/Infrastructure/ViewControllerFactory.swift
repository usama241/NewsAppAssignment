import Foundation
import UIKit

protocol ViewControllerFactoryProtocol {
    
    init(apiClient: APIClientProtocol)
    func newsListViewController(navigationController: UINavigationController) -> NewsListViewController

}

class ViewControllerFactory: ViewControllerFactoryProtocol {
    
    private let apiClient: APIClientProtocol
    required init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func newsListViewController(navigationController: UINavigationController) -> NewsListViewController {
        let movieServices = MovieServices(apiClient: apiClient)
        let viewModel = NewsListViewModel(service: movieServices)
        let coordinator = NewsListCoordinator(navigationController: navigationController, viewControllerFactory: self)
        let viewController = NewsListViewController(viewModel: viewModel, coordinator: coordinator)
        return viewController
    }
}

