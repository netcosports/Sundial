//
//  AutoAlignedController.swift
//  Demo
//
//  Created by Dzianis Shykunets on 5.12.22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import PinLayout
import RxSwift
import Sundial


class AutoAlignedController: UIViewController {
  
  public let leftContainerView = CollectionView<CollectionViewSource>()
  public let rightContainerView = CollectionView<CollectionViewSource>()
  public let autoContainerView = CollectionView<CollectionViewSource>()
  
  typealias ItemCell = CollectionCell<AutoAlignedCell>
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(leftContainerView)
    self.view.addSubview(autoContainerView)
    self.view.addSubview(rightContainerView)
    self.view.backgroundColor = .magenta
    leftContainerView.backgroundColor = .systemBlue
    autoContainerView.backgroundColor = .cyan
    rightContainerView.backgroundColor = .purple
    
    
    
    setupCollection()
    
    let cells: [Cellable] = (0...10).map { index in
      ItemCell.init(data: "Cell \(index)", id: "\(index)")
    }
    
//    let cellId = "2"
//    leftContainerView.autoScrollSubject.onNext(.init(target: .cellId(cellId), position: .center, animated: false))
    
    leftContainerView.source.sections = [Section(cells: cells)]
    leftContainerView.reloadData()
    
    autoContainerView.source.sections = [Section(cells: cells)]
    autoContainerView.reloadData()

    rightContainerView.source.sections = [Section(cells: cells)]
    rightContainerView.reloadData()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    leftContainerView.pin.top(100).horizontally().height(200)
    autoContainerView.pin.below(of: leftContainerView).marginTop(20).horizontally().height(200)
    rightContainerView.pin.below(of: autoContainerView).marginTop(20).horizontally().height(200)
  }
  
  private func setupCollection() {
    let layout = AutoAlignedCollectionViewLayout(
      settings: .init(
        alignment: .start,
        layoutDirection: .ltr
      )
    )
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    leftContainerView.collectionViewLayout = layout
    leftContainerView.decelerationRate = .fast
    leftContainerView.showsHorizontalScrollIndicator = false
    
    let layoutAuto = AutoAlignedCollectionViewLayout(
      settings: .init(
        alignment: UIView.userInterfaceLayoutDirection(for: autoContainerView.semanticContentAttribute) == .rightToLeft ? .end : .start
      )
    )
    layoutAuto.scrollDirection = .horizontal
    layoutAuto.minimumLineSpacing = 0
    layoutAuto.minimumInteritemSpacing = 0
    autoContainerView.collectionViewLayout = layoutAuto
    autoContainerView.decelerationRate = .fast
    autoContainerView.showsHorizontalScrollIndicator = false

    let rtlLayout = AutoAlignedCollectionViewLayout(
      settings: .init(
        alignment: .start,
        layoutDirection: .rtl
      )
    )
    rtlLayout.scrollDirection = .horizontal
    rtlLayout.minimumLineSpacing = 0
    rtlLayout.minimumInteritemSpacing = 0
    rightContainerView.collectionViewLayout = rtlLayout
    rightContainerView.decelerationRate = .fast
    rightContainerView.showsHorizontalScrollIndicator = false
  }
}


class AutoAlignedCell: CollectionViewCell, Reusable, Eventable {
  var eventSubject =  PublishSubject<Event>()
  
  typealias Event = Bool
  
  
  private let root = UIView()
  
  private let titleView = UILabel()
  
  override func setup() {
    super.setup()
    self.clipsToBounds = true
    self.addSubview(root)
    root.addSubview(titleView)
    
    root.backgroundColor = .white
    titleView.textColor = .blue
  }
  
  func setup(with data: String) {
    titleView.text = data
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    root.pin.all(10)
    titleView.pin.top(10).start(10).sizeToFit()
  }
  
  var data: String?
  
  
  typealias Data = String
  
  static func size(for data: String, containerSize: CGSize) -> CGSize {
    return .init(width: containerSize.width - 50, height: containerSize.height)
  }
  
}
