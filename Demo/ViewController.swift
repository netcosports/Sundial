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
import RxSwift

class ViewController: UIViewController {

  let collapsing = CollapsingHeaderViewController()
  let inners = [
    ViewControllerInner(.content(.left), count: 3, margin: 10),
    ViewControllerInner(.content(.right), count: 3, margin: 10),
    ViewControllerInner(.content(.center), count: 3, margin: 10),
    ViewControllerInner(.content(.proportional), count: 3, margin: 0),
    ViewControllerInner(.content(.inverseProportional), count: 3, margin: 0),
    ViewControllerInner(.content(.equalSpacing), count: 5, margin: 0),
    ViewControllerInner(.centered),
    ViewControllerInner(.fillEqual),
    ViewControllerInner(.equal(size: 120)),
    ViewControllerInner(.left(offset: 80)),
    ViewControllerInner(.right(offset: 80))
  ]
  let customViews = CustomViewsViewController()

  let collectionView = CollectionView<CollectionViewPagerSource>()
  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self

    let layout = CollectionViewLayout(hostPagerSource: collectionView.source) { [weak self] in
      return self?.titles ?? []
    }

    layout.rx.ready.subscribe(onNext: {
      print("Rx: layout is ready")
    }).disposed(by: disposeBag)

    layout.ready = {
      print("Callback: layout is ready")
    }

    collectionView.collectionViewLayout = layout

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      if #available(iOS 11.0, *) {
        $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      } else {
        $0.top.equalTo(topLayoutGuide.snp.bottom)
      }
      $0.bottom.leading.trailing.equalToSuperview()
    }

    collapsing.view.backgroundColor = .red

    for controller in inners {
      controller.view.backgroundColor = .red
    }

    customViews.view.backgroundColor = .red

    collectionView.source.reloadData()
  }
}

extension ViewController: CollectionViewPager {

  var pages: [Page] {
    var controllers: [UIViewController] = inners
    controllers.insert(collapsing, at: 0)
    controllers.append(customViews)

    return controllers.enumerated().map { Page(controller: $1, id: "Title \($0)") }
  }
}

extension ViewController {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return [
      TitleCollectionViewCell.TitleViewModel(title: "collapsing", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "content(.left)", indicatorColor: .blue),
      TitleCollectionViewCell.TitleViewModel(title: "content(.right)", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "content(.center)", indicatorColor: .orange),
      TitleCollectionViewCell.TitleViewModel(title: "content(.proportional)", indicatorColor: .red),
      TitleCollectionViewCell.TitleViewModel(title: "content(.inverseProportional)", indicatorColor: .red),
      TitleCollectionViewCell.TitleViewModel(title: "content(.equalSpacing)", indicatorColor: .red),
      TitleCollectionViewCell.TitleViewModel(title: "centered", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "fillEqual", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "equal(size: 120)", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "left(offset: 80)", indicatorColor: .orange),
      TitleCollectionViewCell.TitleViewModel(title: "right(offset: 80)", indicatorColor: .brown),
      TitleCollectionViewCell.TitleViewModel(title: "Custom Views", indicatorColor: .brown),
    ]
  }
}
