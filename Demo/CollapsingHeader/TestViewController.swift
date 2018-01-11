//
//  TestViewController.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import Astrolabe
import Sundial

class TestCell: CollectionViewCell, Reusable {

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .black
    title.textAlignment = .center
    return title
  }()

  override func setup() {
    super.setup()
    contentView.addSubview(title)
    title.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  typealias Data = UIColor

  func setup(with data: Data) {
    guard let indexPath = indexPath else { return }
    title.text = "\(indexPath.item)"
  }

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 76)
  }
}

class TestViewController: UIViewController, Accessor, CollapsingItem {

  typealias Cell = CollectionCell<TestCell>
  let containerView = CollectionView<CollectionViewSource>()

  let visible = Variable<Bool>(false)
  var scrollView: UIScrollView {
    return containerView
  }
//  var extraInset: UIEdgeInsets {
//    return UIEdgeInsets(top: 100, left: 0.0, bottom: 50, right: 0.0)
//  }
  let color: UIColor
  let numberOfItems: Int
  init(_ color: UIColor, numberOfItems: Int = 3) {
    self.color = color
    self.numberOfItems = numberOfItems
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if numberOfItems > 1 {
      let cells: [Cellable] = (1...numberOfItems).map { _ in Cell(data: color) }
      sections = [ Section(cells: cells) ]
    }
    view.addSubview(containerView)
    containerView.snp.remakeConstraints { $0.edges.equalToSuperview() }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    visible.value = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    visible.value = false
  }
}

class TestPagerViewControllerInner: UIViewController {

  let controller1 = TestViewController(.red)
  let controller2 = TestViewController(.blue, numberOfItems: 0)
  let controller3 = TestViewController(.green)
  let controller4 = TestViewController(.lightGray)
  let controller5 = TestViewController(.black)

  let offsetVariable = Variable<CGFloat>(0.0)
  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollectionViewLayout<CollectionViewPagerSource, TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.TitleViewModel>>

  let collasingItemsSubject = PublishSubject<[CollapsingItem]>()

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            bottomStripSpacing: 0.0,
                            inset: .zero,
                            alignment: .topOffset(variable: offsetVariable))

    let layout = Layout(hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }
    layout.pageStripBackgroundColor = .red
    collectionView.collectionViewLayout = layout
    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }
    collectionView.source.reloadData()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    DispatchQueue.main.async {
      self.collasingItemsSubject.onNext([
        self.controller1, self.controller2, self.controller3, self.controller4, self.controller5
      ])
    }
  }
}

extension TestPagerViewControllerInner: CollectionViewPager {

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

extension TestPagerViewControllerInner {

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

