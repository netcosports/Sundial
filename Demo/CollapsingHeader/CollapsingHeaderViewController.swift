//
//  CollapsingHeaderViewController.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial
import RxSwift

class Header: CollectionViewCell {

  override func setup() {
    super.setup()

    contentView.backgroundColor = .purple
  }
}

class CollapsingHeaderViewController: UIViewController {

  let disposeBag = DisposeBag()

  let controller1 = TestViewController(.red)
  let controller2 = TestViewController(.blue)
  let controller3 = TestPagerViewControllerInner()
  let controller4 = TestViewController(.lightGray)
  let controller5 = TestViewController(.black)

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollapsingCollectionViewLayout<CollectionViewPagerSource, Header, TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.TitleViewModel>>

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            bottomStripSpacing: 0.0,
                            inset: .zero)

    var items: [CollapsingItem] = [controller1, controller2]
    let innerControllers: [CollapsingItem] = [controller3.controller1,
                            controller3.controller2,
                            controller3.controller3,
                            controller3.controller4,
                            controller3.controller5]

    items.append(contentsOf: innerControllers)
    items.append(contentsOf: [controller4, controller5])

    let layout = Layout(items: items, hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }
    layout.headerHeight.asDriver()
      .map { $0 + 80.0 }
      .drive(controller3.offsetVariable)
      .disposed(by: disposeBag)

    collectionView.collectionViewLayout = layout

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    controller1.view.backgroundColor = .clear
    controller2.view.backgroundColor = .clear
    controller3.view.backgroundColor = .clear
    controller4.view.backgroundColor = .clear
    controller5.view.backgroundColor = .clear

    collectionView.source.reloadData()
  }
}

extension CollapsingHeaderViewController: CollectionViewPager {

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

extension CollapsingHeaderViewController {

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
