//
//  TestViewController.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Astrolabe
import Sundial

class ColoredTestCell: CollectionViewCell, Reusable {

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

class TestLoaderViewController: UIViewController, Accessor, CollapsingItem, Loadable, Containerable {

  typealias Cell = CollectionCell<ColoredTestCell>
  let containerView = CollectionView<LoaderDecoratorSource<CollectionViewSource>>()

  let visible = BehaviorRelay<Bool>(value: false)
  var scrollView: UIScrollView {
    return containerView
  }
  var followDirection: Bool {
    return true
  }
  var sections: [Sectionable] {
    get {
      return source.sections
    }

    set {
      source.sections = newValue
    }
  }

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

    source.loader = LoaderMediator(loader: self)
    source.hostViewController = self

    view.addSubview(containerView)
    containerView.snp.remakeConstraints { $0.edges.equalToSuperview() }
  }

  func load(for intent: LoaderIntent) -> SectionObservable? {
    if numberOfItems > 1 {
      let cells: [Cellable] = (1...numberOfItems).map { _ in Cell(data: color) }
      let sections = [ Section(cells: cells) ]
      return Observable.just(sections).delay(1.0, scheduler: MainScheduler.instance)
    }

    return nil
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    visible.accept(true)
    source.appear()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    visible.accept(false)
    source.disappear()
  }
}

class TestViewController: UIViewController, Accessor, CollapsingItem {

  typealias Cell = CollectionCell<ColoredTestCell>
  let containerView = CollectionView<CollectionViewSource>()

  let visible = BehaviorRelay<Bool>(value: false)
  var scrollView: UIScrollView {
    return containerView
  }

  let color: UIColor
  let numberOfItems: Int
  init(_ color: UIColor, numberOfItems: Int = 3) {
    self.color = color
    self.numberOfItems = numberOfItems
    super.init(nibName: nil, bundle: nil)
  }

  var sections: [Sectionable] {
    get {
      return source.sections
    }

    set {
      source.sections = newValue
    }
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
    visible.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    visible.accept(false)
  }
}

class TestPagerViewControllerInner: UIViewController {

  let controller1 = TestViewController(.red)
  let controller2 = TestLoaderViewController(.lightGray)
  let controller3 = TestLoaderViewController(.green)
  let controller4 = TestViewController(.blue, numberOfItems: 0)
  let controller5 = TestViewController(.black)

  let offsetBehaviorRelay = BehaviorRelay<CGFloat>(value: 0.0)
  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollectionViewLayout

  let collasingItemsSubject = PublishSubject<[CollapsingItem]>()

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self
    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: 12.0,
                            bottomStripSpacing: 0.0,
                            backgroundColor: .red,
                            inset: .zero,
                            alignment: .topOffset(behaviorRelay: offsetBehaviorRelay),
                            jumpingPolicy: .skip(pages: 1))

    let layout = Layout(hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }
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

