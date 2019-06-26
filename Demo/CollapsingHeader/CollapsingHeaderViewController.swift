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

class Header: CollectionViewCell, Reusable {

  typealias Data = String

  func setup(with data: String) {
    title.text = data
  }

  static func size(for data: String, containerSize: CGSize) -> CGSize {
    return .zero
  }

  let title = UILabel()

  override func setup() {
    super.setup()

    contentView.backgroundColor = .purple

    title.textColor = .white
    contentView.addSubview(title)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    title.frame = contentView.bounds.insetBy(dx: 15, dy: 15)
  }

}

class CollapsingHeaderViewController: UIViewController {

  let disposeBag = DisposeBag()

  let controller1 = TestViewController(.red)
  let controller2 = TestViewController(.blue)
  let controllerLoader = TestLoaderViewController(.orange, numberOfItems: 20)
  let controller3 = TestPagerViewControllerInner()
  let controller4 = TestViewController(.lightGray)
  let controller5 = TestLoaderViewController(.black)

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollapsingCollectionViewLayout

  let collasingItemsSubject = PublishSubject<[CollapsingItem]>()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            bottomStripSpacing: 0.0,
                            inset: .zero,
                            jumpingPolicy: .skip(pages: 1))
    let layout = Layout(items: [], hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }
    layout.maxHeaderHeight.accept(300)
    layout.minHeaderHeight.accept(100)
    layout.headerHeight.accept(layout.maxHeaderHeight.value)
    layout.headerHeight.asDriver()
      .map { $0 + 80.0 }
      .drive(controller3.offsetBehaviorRelay)
      .disposed(by: disposeBag)

    collasingItemsSubject.asDriver(onErrorJustReturn: []).drive(onNext: { [weak layout] collasingItems in
      layout?.append(collapsingItems: collasingItems)
    }).disposed(by: disposeBag)

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    collectionView.collectionViewLayout = layout
    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    collasingItemsSubject.onNext([controller1, controller2, controllerLoader, controller4, controller5])
    controller3.collasingItemsSubject.bind(to: collasingItemsSubject).disposed(by: disposeBag)

    controller1.view.backgroundColor = .clear
    controller2.view.backgroundColor = .clear
    controllerLoader.view.backgroundColor = .clear
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
      Page(controller: controllerLoader, id: "Loader"),
      Page(controller: controller3, id: "Title 3"),
      Page(controller: controller4, id: "Title 4"),
      Page(controller: controller5, id: "Title 5")
    ]
  }

  func section(with cells: [Cellable]) -> Sectionable {
    return CollectionHeaderSection<Header>(cells: cells, headerData: "Customizable Header title")
  }

}

extension CollapsingHeaderViewController {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return [
      TitleCollectionViewCell.TitleViewModel(title: "Blue", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "Black", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "Loader", indicatorColor: .orange),
      TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
    ]
  }
}
