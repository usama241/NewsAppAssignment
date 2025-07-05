import Foundation
import UIKit
import Combine
import SafariServices

class NewsListViewController: UIViewController {
    
    //MARK: - Properties
    var viewModel: NewsListViewModel!
    var coordinator: NewsListCoordinator!
    private var subscribers: Set<AnyCancellable> = []

    // MARK: - UI Components
    private let tableView = UITableView()
    private let noHistoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Movie List is Empty!"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

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
        self.title = "Movies List"
        view.backgroundColor = .systemBackground
        setupUI()
        setupTableView()
        bindViews()
        fetchMoviesList()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(noHistoryLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // TableView Constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // No History Label Centered
            noHistoryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noHistoryLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.register(NewsListTableViewCell.self, forCellReuseIdentifier: "NewsListTableViewCell")
    }

    // MARK: - Data Binding
    private func bindViews() {
        viewModel.$newsList
            .receive(on: RunLoop.main)
            .sink { [weak self] movies in
                guard let self = self else { return }
                let isEmpty = movies?.isEmpty ?? true
                self.noHistoryLabel.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                self.tableView.reloadData()
            }
            .store(in: &subscribers)
    }

    // MARK: - Fetch
    private func fetchMoviesList() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await viewModel.newsList()
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
        return viewModel.newsList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsListTableViewCell", for: indexPath) as? NewsListTableViewCell else {
            return UITableViewCell()
        }
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .clear
        let title = viewModel.newsList?[indexPath.row].title ?? ""
        let source = viewModel.newsList?[indexPath.row].source?.name ?? ""
        let imageURL = viewModel.newsList?[indexPath.row].urlToImage ?? ""

        cell.configure(title: title, source: source, imageURL: imageURL)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let urlString = viewModel.newsList?[indexPath.row].url,
                let url = URL(string: urlString) else {
              return
          }
          
          let safariVC = SFSafariViewController(url: url)
          safariVC.modalPresentationStyle = .formSheet // optional
          present(safariVC, animated: true)
    }
}
