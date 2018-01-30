//
//  ViewControllerInner.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial

class ViewControllerInner: UIViewController {

  let controller1 = UIViewController()
  let controller2 = UIViewController()
  let controller3 = UIViewController()
  let controller4 = UIViewController()
  let controller5 = UIViewController()

  let anchor: Anchor

  init(_ anchor: Anchor) {
    self.anchor = anchor
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollectionViewLayout<CustomDecorationView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.TitleViewModel>>>

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self

    let margin: CGFloat
    switch anchor {
    case .fillEqual:
      margin = 0.0
    default:
      margin = 80.0
    }

    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: margin,
                            bottomStripSpacing: 0.0,
                            anchor: anchor,
                            inset: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin))

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

extension ViewControllerInner: CollectionViewPager {

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

extension ViewControllerInner {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return [
      TitleCollectionViewCell.TitleViewModel(title: "Blue", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "Black", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
    ]
  }
}
