//
//  StickyHeaderController.swift
//  Demo
//
//  Created by Sergei Mikhan on 17.12.21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Sundial
import Astrolabe
import SnapKit
import RxSwift
import RxCocoa

public  class HeaderTestCell: CollectionViewCell, Reusable, Eventable {
  public var eventSubject = PublishSubject<Event>()
  
  public typealias Event = Bool
  
  public var data: Data?
  
  public typealias Data = String
  

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    return title
  }()

  open override func setup() {
    super.setup()
    contentView.backgroundColor = .orange
    contentView.addSubview(title)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = contentView.bounds
    title.text = "HEADER height is \(Int(self.frame.height))"
  }

  public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let stickyLayoutAttributes = layoutAttributes as? StickyHeaderCollectionViewLayoutAttributes {
      print("progress is \(stickyLayoutAttributes)")
    }
    setNeedsLayout()
  }
  public func setup(with data: Data) {
    
  }
  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 276)
  }
}

class StickyHeaderController: UIViewController, CollapsingItem {
  var scrollView: UIScrollView {
    return containerView
  }

  let visible = BehaviorRelay<Bool>(value: false)


  let containerView = CollectionView<CollectionViewSource>()
  let settings =  StickyHeaderCollectionViewLayout.Settings(
    collapsing: true,
    sticky: true,
    minHeight: 120.0,
    alignToEdges: true,
    insetBehavior: .additionalInset(value: 180)
  )

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(containerView)

    containerView.collectionViewLayout = StickyHeaderCollectionViewLayout(settings: settings)
    containerView.backgroundColor = .red
    var cells: [Cellable] = (1...25).map { "Item \($0)" }.map { CollectionCell<TestCell>(data: $0, id: $0) }
    cells.insert(CollectionCell<HeaderTestCell>(data: "", id: "HeaderTestCell"), at: 0)
    containerView.source.sections = [Section(cells: cells)]
    containerView.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    visible.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    visible.accept(false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerView.frame = view.bounds
  }
}
