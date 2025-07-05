import Foundation
import UIKit
import Combine
import SafariServices

class NewsListViewController: UIViewController {
    
    //MARK: - Properties
    var viewModel: NewsViewModel!
    var coordinator: NewsListCoordinator!
    private var subscribers: Set<AnyCancellable> = []
    
    // MARK: - UI Components
    private let tableView = UITableView()
    private let noHistoryLabel: UILabel = {
        let label = UILabel()
        label.text = "News List is Empty!"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let refreshControl = UIRefreshControl()
    
    // MARK: - Init
    init(viewModel: NewsViewModel, coordinator: NewsListCoordinator) {
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
        self.title = "News List"
        view.backgroundColor = .systemBackground
        setupUI()
        setupTableView()
        bindViews()
        fetchMoviesList(forceRefresh: false)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(noHistoryLabel)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            noHistoryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noHistoryLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
    }
    
    @objc private func refreshData() {
        fetchMoviesList(forceRefresh: true)
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
                let isEmpty = news.isEmpty
                self.noHistoryLabel.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            .store(in: &subscribers)
    }
    
    // MARK: - Fetch
    private func fetchMoviesList(forceRefresh: Bool) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await viewModel.loadArticles(forceRefresh: forceRefresh)
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                    self.noHistoryLabel.isHidden = false
                }
            }
        }
    }
}


extension NewsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsListTableViewCell", for: indexPath) as? NewsListTableViewCell else {
            return UITableViewCell()
        }
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .clear
        let title = viewModel.articles[indexPath.row].title ?? ""
        let source = viewModel.articles[indexPath.row].source ?? ""
        let imageURL = viewModel.articles[indexPath.row].urlToImage ?? ""
        
        cell.configure(title: title, source: source, imageURL: imageURL)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let urlString = viewModel.articles[indexPath.row].url,
              let url = URL(string: urlString) else {
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .formSheet
        present(safariVC, animated: true)
    }
}
