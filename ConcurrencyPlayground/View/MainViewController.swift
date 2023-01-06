//
//  MainViewController.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import UIKit

final class MainViewController: UIViewController {

    // MARK: Subviews

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { [weak self] section, environment in
            self?.dataSource.sectionIdentifier(for: section)?.layout(with: environment)
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: Properties

    private let viewModel: MainViewModel

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, indexPath, itemIdentifier in
            var configuration = UIListContentConfiguration.subtitleCell()
            configuration.text = itemIdentifier.repository.name
            configuration.secondaryText = itemIdentifier.repository.description
            configuration.image = UIImage()
            configuration.imageProperties.cornerRadius = 4
            configuration.imageProperties.maximumSize = CGSize(width: 60, height: 60)
            self?.viewModel.fetchImage(for: itemIdentifier) { image in
                var configuration = cell.contentConfiguration as? UIListContentConfiguration
                configuration?.image = image
                cell.contentConfiguration = configuration
            }
            cell.contentConfiguration = configuration
            cell.accessories = [.disclosureIndicator()]
        }
        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
        return dataSource
    }()

    // MARK: Lifecycle

    init(with viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureNavigation()
        bindViewModel()

        viewModel.fetchData()
    }
}

private extension MainViewController {
    func configureSubviews() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }

    func configureNavigation() {
        navigationItem.title = "Repository"
    }

    func bindViewModel() {
        viewModel.updateSnapshot = { [weak self] snapshot in
            self?.dataSource.apply(snapshot)
        }
    }
}
