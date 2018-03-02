//
//  ViewController.swift
//  Sundial
//
//  Created by Sergei Mikhan on 9/28/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial
import SnapKit

class ViewController: UIViewController {

  let controller0 = CollapsingHeaderViewController()
  let controller1 = ViewControllerInner(.content)
  let controller2 = ViewControllerInner(.centered)
  let controller3 = ViewControllerInner(.fillEqual)
  let controller4 = ViewControllerInner(.equal(size: 120))
  let controller5 = ViewControllerInner(.left(offset: 80))
  let controller6 = ViewControllerInner(.right(offset: 80))
  let controller7 = CustomViewsViewController()

  let collectionView = CollectionView<CollectionViewPagerSource>()

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    collectionView.collectionViewLayout = CollectionViewLayout(hostPagerSource: collectionView.source) { [weak self] in
      return self?.titles ?? []
    }

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    controller0.view.backgroundColor = .red
    controller1.view.backgroundColor = .red
    controller2.view.backgroundColor = .red
    controller3.view.backgroundColor = .red
    controller4.view.backgroundColor = .red
    controller5.view.backgroundColor = .red
    controller6.view.backgroundColor = .red
    controller7.view.backgroundColor = .red

    collectionView.source.reloadData()
  }
}

extension ViewController: CollectionViewPager {

  var pages: [Page] {
    return [
      Page(controller: controller0, id: "Title 0"),
      Page(controller: controller1, id: "Title 1"),
      Page(controller: controller2, id: "Title 2"),
      Page(controller: controller3, id: "Title 3"),
      Page(controller: controller4, id: "Title 4"),
      Page(controller: controller5, id: "Title 5"),
      Page(controller: controller6, id: "Title 6"),
      Page(controller: controller7, id: "Title 7"),
    ]
  }
}

extension ViewController {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return [
      TitleCollectionViewCell.TitleViewModel(title: "collapsing", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "content", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "centered", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "fillEqual", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "equal(size: 120)", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "left(offset: 80)", indicatorColor: .orange),
      TitleCollectionViewCell.TitleViewModel(title: "right(offset: 80)", indicatorColor: .brown),
      TitleCollectionViewCell.TitleViewModel(title: "Custom Views", indicatorColor: .brown),
    ]
  }
}
