//
//  MainViewControllerSection.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import UIKit

extension MainViewController {
    enum Section: Hashable {
        case main

        func layout(with environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
            let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            return section
        }
    }
}
