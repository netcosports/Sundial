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
  
  public let containerView = CollectionView<CollectionViewSource>()
  
  typealias ItemCell = CollectionCell<AutoAlignedCell>
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(containerView)
    self.view.backgroundColor = .magenta
    containerView.backgroundColor = .systemBlue
    
    setupCollection()
    
    let cells: [Cellable] = (0...10).map { index in
      ItemCell.init(data: "Cell \(index)", id: "\(index)")
    }
    
    containerView.source.sections = [Section(cells: cells)]
    containerView.reloadData()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerView.pin.top(100).horizontally().height(400)
  }
  
  private func setupCollection() {
    let layout = AutoAlignedCollectionViewLayout(
      settings: .init(
        alignment: .start
      )
    )
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    containerView.collectionViewLayout = layout
    containerView.decelerationRate = .fast
    containerView.showsHorizontalScrollIndicator = false
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
