//
//  CollectionViewLayout.swift
//  Sundial
//
//  Created by Eugen Filipkov on 4/17/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

open class GenericCollectionViewLayout<DecorationView: CollectionViewCell & DecorationViewPageable>: PlainCollectionViewLayout {

  public typealias ViewModel = DecorationView.TitleCell.Data
  public typealias PagerClosure = ()->[ViewModel]

  open var pager: PagerClosure?

  open var decorationFrame: CGRect {
    guard let collectionView = collectionView else { return .zero }

    let topOffset: CGFloat
    switch settings.alignment {
    case .top:
      topOffset = 0.0
    case .topOffset(let variable):
      topOffset = variable.value
    }

    return CGRect(x: collectionView.contentOffset.x,
                  y: topOffset,
                  width: collectionView.frame.width,
                  height: settings.stripHeight)
  }

  // MARK: - Init

  public required init(hostPagerSource: Source, settings: Settings? = nil , pager: PagerClosure?) {
    self.pager = pager
    super.init(hostPagerSource: hostPagerSource, settings: settings)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Override

  open override func prepare() {
    register(DecorationView.self, forDecorationViewOfKind: DecorationViewId)
    super.prepare()
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let sourceAttributes = super.layoutAttributesForElements(in: rect) ?? []
    var attributes = sourceAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

    addDecorationAttributes(to: &attributes)
    addJumpAttributes(to: &attributes)
    return attributes
  }

  open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attributes = layoutAttributesForElements(in: .infinite) else { return nil }

    for attribute in attributes {
      if attribute.representedElementCategory == .cell && attribute.indexPath == indexPath {
        return attribute
      }
    }
    return nil
  }

  open override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard elementKind == DecorationViewId, indexPath == IndexPath(item: 0, section: 0) else { return nil }
    return decorationAttributes(with: pager?())
  }

  // MARK: - Open

  open func adjustItem(frame: CGRect) -> CGRect {
    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  open func decorationAttributes(with titles: [ViewModel]?) -> DecorationView.Attributes? {
    guard let titles = titles, titles.count > 0 else {
      return nil
    }

    let settings = self.settings
    let validPagesRange = 0...(titles.count - settings.pagesOnScreen)
    let decorationIndexPath = IndexPath(item: 0, section: 0)
    let decorationAttributes = DecorationView.Attributes(forDecorationViewOfKind: DecorationViewId, with: decorationIndexPath)
    decorationAttributes.zIndex = 1024
    decorationAttributes.settings = settings
    decorationAttributes.titles = titles
    decorationAttributes.hostPagerSource = hostPagerSource
    decorationAttributes.selectionClosure = { [weak self] in
      guard let `self` = self else { return }

      let item = $0.clamp(to: validPagesRange)
      self.select(item: item, jumpingPolicy: settings.jumpingPolicy)
    }
    decorationAttributes.frame = decorationFrame

    return decorationAttributes
  }

  // MARK: - Internal

  func addDecorationAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > 0 else { return }
    guard let decorationAttributes = self.decorationAttributes(with: pager?()) else {
      return
    }

    attributes.forEach {
      $0.frame = adjustItem(frame: $0.frame)
    }
    attributes.append(decorationAttributes)
  }

}
