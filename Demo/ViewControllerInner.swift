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

  var inverted = false

  let anchor: Anchor
  let count: Int
  let margin: CGFloat

  init(_ anchor: Anchor, count: Int = 5, margin: CGFloat = 80) {
    self.anchor = anchor
    self.count = count
    self.margin = margin
    guard (1 ... 5).contains(count) else { fatalError() }
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = GenericCollectionViewLayout<CustomDecorationView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.TitleViewModel>>>

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self

    let margin: CGFloat
    switch anchor {
    case .fillEqual:
      margin = 0.0
    default:
      margin = self.margin
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

    let button = UIButton()
    button.backgroundColor = .magenta
    button.addTarget(self, action: #selector(click), for: UIControl.Event.touchUpInside)
    controller1.view.addSubview(button)
    button.snp.remakeConstraints {
      $0.height.width.equalTo(120)
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(60)
    }
  }

  @objc func click() {
    self.inverted = !self.inverted
    self.collectionView.reloadData()
  }
}

extension ViewControllerInner: CollectionViewPager {

  var pages: [Page] {
    return Array([
      Page(controller: controller1, id: "Title 1"),
      Page(controller: controller2, id: "Title 2"),
      Page(controller: controller3, id: "Title 3"),
      Page(controller: controller4, id: "Title 4"),
      Page(controller: controller5, id: "Title 5")
      ].prefix(count))
  }
}

extension ViewControllerInner {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    if inverted {
      return Array([
        TitleCollectionViewCell.TitleViewModel(title: "Mid Blue", id: "Inverted Mid Blue", indicatorColor: .magenta),
        TitleCollectionViewCell.TitleViewModel(title: "Super Long Black", indicatorColor: .black),
        TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
        TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
        TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
      ].prefix(count))
    } else {
      return Array([
        TitleCollectionViewCell.TitleViewModel(title: "Mid Blue", indicatorColor: .blue),
        TitleCollectionViewCell.TitleViewModel(title: "Super Long Black", indicatorColor: .black),
        TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
        TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
        TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
        ].prefix(count))
    }
  }
}
