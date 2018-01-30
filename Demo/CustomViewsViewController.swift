//
//  CustomViewsViewController.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/19/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial

class CustomViewsViewController: UIViewController {

  let controller1 = UIViewController()
  let controller2 = UIViewController()
  let controller3 = UIViewController()
  let controller4 = UIViewController()
  let controller5 = UIViewController()

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollectionViewLayout<DecorationView<CustomTitleCollectionViewCell, CustomMarkerDecorationView>>

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            bottomStripSpacing: 0.0,
                            anchor: .equal(size: 140),
                            inset: .zero)

    collectionView.collectionViewLayout = Layout(hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    controller1.view.backgroundColor = .blue
    controller2.view.backgroundColor = .black
    controller3.view.backgroundColor = .green
    controller4.view.backgroundColor = .gray
    controller5.view.backgroundColor = .orange

    collectionView.source.reloadData()
  }
}

extension CustomViewsViewController: CollectionViewPager {

  var pages: [Page] {
    return [
      Page(controller: controller1, id: "Title 1"),
      Page(controller: controller2, id: "Title 2"),
      Page(controller: controller3, id: "Title 3"),
      Page(controller: controller4, id: "Title 4"),
      Page(controller: controller5, id: "Title 5")
    ]
  }
}

extension CustomViewsViewController {

  var titles: [CustomTitleCollectionViewCell.CustomTitleViewModel] {
    return [
      CustomTitleCollectionViewCell.CustomTitleViewModel(title: "Blue", indicatorColor: .blue),
      CustomTitleCollectionViewCell.CustomTitleViewModel(title: "Black", indicatorColor: .black),
      CustomTitleCollectionViewCell.CustomTitleViewModel(title: "Green", indicatorColor: .green),
      CustomTitleCollectionViewCell.CustomTitleViewModel(title: "Gray", indicatorColor: .gray),
      CustomTitleCollectionViewCell.CustomTitleViewModel(title: "Orange", indicatorColor: .orange)
    ]
  }
}
