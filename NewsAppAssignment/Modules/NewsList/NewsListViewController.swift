import Foundation
import UIKit
import Combine
import SafariServices

class NewsListViewController: UIViewController {
    
    // MARK: - Properties
    var viewModel: NewsListViewModel!
    var coordinator: NewsListCoordinator!
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Init
    init(viewModel: NewsListViewModel, coordinator: NewsListCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard is not supported")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupUI()
        setupTableView()
        bindViews()
        fetchNewsList(forceRefresh: false)
    }
    
    // MARK: - Configuration
    private func configureView() {
        title = "Latest News"
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        fetchNewsList(forceRefresh: true)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.register(NewsListTableViewCell.self, forCellReuseIdentifier: "NewsListTableViewCell")
    }
    
    // MARK: - Data Binding
    private func bindViews() {
        viewModel.$articles
            .receive(on: RunLoop.main)
            .sink { [weak self] news in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            .store(in: &subscribers)
    }
    
    // MARK: - Fetching Data
    private func fetchNewsList(forceRefresh: Bool) {
        Task { [weak self] in
            guard let self = self else { return }
            await MainActor.run { self.activityIndicator.startAnimating() }
            
            do {
                try await viewModel.loadArticles(forceRefresh: forceRefresh)
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
            
            await MainActor.run { self.activityIndicator.stopAnimating() }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NewsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsListTableViewCell", for: indexPath) as? NewsListTableViewCell else {
            return UITableViewCell()
        }
        
        let article = viewModel.articles[indexPath.row]
        let title = article.title ?? ""
        let source = article.source ?? ""
        let imageURL = article.urlToImage ?? ""
        
        cell.configure(title: title, source: source, imageURL: imageURL)
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let urlString = viewModel.articles[indexPath.row].url, let url = URL(string: urlString) else { return }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .formSheet
        present(safariVC, animated: true)
    }
}
