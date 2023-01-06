//
//  MainViewControllerItem.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import UIKit

extension MainViewController {
    struct Item: Hashable {
        let repository: Repository
        let image: UIImage?

        func update(image: UIImage?) -> Self {
            Item(repository: self.repository,
                 image: image)
        }
    }
}
