//
//  PagerHeaderCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 08/23/19.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

open class PagerHeaderCollectionViewLayout: PlainCollectionViewLayout {

  static let headerIndex = IndexPath(index: 0)
  static let collapsingIndex = IndexPath(index: 1)

  open var pagerHeaderFrame: CGRect {
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

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let sourceAttributes = super.layoutAttributesForElements(in: rect) ?? []
    var attributes = sourceAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
    addPagerHeaderAttributes(to: &attributes)
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

  open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard elementKind == PagerHeaderSupplementaryViewKind, indexPath == PagerHeaderCollectionViewLayout.headerIndex else {
      return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    return pagerHeaderViewAttributes()
  }

  // MARK: - Open
  open func pagerHeaderViewAttributes() -> PagerHeaderViewAttributes? {
    let pagerHeaderAttributes = PagerHeaderViewAttributes(forSupplementaryViewOfKind: PagerHeaderSupplementaryViewKind,
                                                          with: PagerHeaderCollectionViewLayout.headerIndex)
    pagerHeaderAttributes.zIndex = 1024
    pagerHeaderAttributes.settings = self.settings
    pagerHeaderAttributes.hostPagerSource = hostPagerSource
    pagerHeaderAttributes.selectionClosure = { [weak self] in
      guard let self = self else { return }
      self.select(item: $0, jumpingPolicy: self.settings.jumpingPolicy)
    }
    pagerHeaderAttributes.frame = self.pagerHeaderFrame
    return pagerHeaderAttributes
  }
}

extension PagerHeaderCollectionViewLayout {

  func adjustItem(frame: CGRect) -> CGRect {
    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  func addPagerHeaderAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > settings.numberOfTitlesWhenHidden else { return }
    guard let pagerHeaderViewAttributes = self.pagerHeaderViewAttributes() else {
      return
    }
    attributes.forEach {
      $0.frame = adjustItem(frame: $0.frame)
    }
    attributes.append(pagerHeaderViewAttributes)
  }
}

