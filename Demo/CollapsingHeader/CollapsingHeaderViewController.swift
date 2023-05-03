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
import RxCocoa

class Header: CollectionViewCell, Reusable {
  
  var data: Data?
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

  //let controller1 = StickyHeaderController()
  let controller2 = TestViewController(.blue)
  let controllerLoader = TestViewController(.orange, numberOfItems: 20)
  let controller3 = TestPagerViewControllerInner()
  let controller4 = TestViewController(.lightGray)
  let controller5 = TestViewController(.black)

  let collectionView = CollectionView<CollectionViewReusedPagerSource>()

  typealias Layout = PagerHeaderCollectionViewLayout

  let collasingItemsSubject = PublishSubject<[CollapsingItem]>()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            stripInsets: .init(top: 0.0, left: 0.0, bottom: 44.0, right: 0.0),
                            inset: .zero,
                            jumpingPolicy: .skip(pages: 1))
    let layout = Layout(hostPagerSource: collectionView.source, settings: settings)
    layout.maxHeaderHeight.accept(300)
    layout.minHeaderHeight.accept(100)
    layout.maxFooterHeight.accept(300)
    layout.minFooterHeight.accept(0.0)
    layout.headerHeight.accept(layout.maxHeaderHeight.value)
    layout.headerHeight.asDriver()
      .map { $0 + 80.0 }
      .drive(controller3.offsetBehaviorRelay)
      .disposed(by: disposeBag)

    collasingItemsSubject.asDriver(onErrorJustReturn: []).drive(onNext: { [weak layout] collasingItems in
      layout?.append(collapsingItems: collasingItems)
    }).disposed(by: disposeBag)

    collectionView.source.hostViewController = self
    //collectionView.source.pager = self
    collectionView.collectionViewLayout = layout
    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    collasingItemsSubject.onNext([controller2, controllerLoader, controller4, controller5])
    controller3.collasingItemsSubject.bind(to: collasingItemsSubject).disposed(by: disposeBag)

    //controller1.view.backgroundColor = .clear
    controller2.view.backgroundColor = .clear
    controllerLoader.view.backgroundColor = .clear
    controller3.view.backgroundColor = .clear
    controller4.view.backgroundColor = .clear
    controller5.view.backgroundColor = .clear

    collectionView.reloadData()
  }

}
//
//extension CollapsingHeaderViewController: CollectionViewPager {
//
//  var pages: [Page] {
//    return [
//      Page(controller: controller1, id: "Title 1"),
//      Page(controller: controller2, id: "Title 2"),
//      Page(controller: controllerLoader, id: "Loader"),
//      Page(controller: controller3, id: "Title 3"),
//      Page(controller: controller4, id: "Title 4"),
//      Page(controller: controller5, id: "Title 5")
//    ]
//  }
//
//  typealias Supplementary = PagerHeaderSupplementaryView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.Data>>
//
//  func section(with cells: [Cellable]) -> Sectionable {
//    let pagerSupplementary = CollectionCell<Supplementary>(data: titles,
//                                                           type: .custom(kind: PagerHeaderSupplementaryViewKind))
//
//    let collapsingSupplementary = CollectionCell<Header>(data: "Customizable Header title",
//                                                         type: .custom(kind: PagerHeaderCollapsingSupplementaryViewKind))
//
//    let pagerFooter = CollectionCell<Header>(data: "Customizable Footer title",
//                                             type: .custom(kind: PagerHeaderCollapsingFooterViewKind))
//
//
//    return MultipleSupplementariesSection(supplementaries: [pagerSupplementary, collapsingSupplementary, pagerFooter], cells: cells)
//  }
//}

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
