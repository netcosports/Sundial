//
//  AutoAlignedCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 8/14/19.
//

import UIKit

open class AutoAlignedCollectionViewLayout: EmptyViewCollectionViewLayout {

  public struct Settings {

    public enum Alignment {
      case start
      case center
      case end
    }

    public enum ScrollTarget {
      case closest
      case factor(Double)
    }

    public let alignment: Alignment
    public let inset: CGFloat
    public let target: ScrollTarget

    public init(alignment: Alignment, inset: CGFloat = 0.0, target: ScrollTarget = .closest) {
      self.alignment = alignment
      self.inset = inset
      self.target = target
    }
  }

  open var settings: Settings {
    didSet {
      invalidateLayout()
    }
  }

  public init(settings: Settings) {
    self.settings = settings
    super.init()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func prepare() {
    switch scrollDirection {
    case .horizontal:
      collectionView?.contentInset = UIEdgeInsets(top: sectionInset.top, left: startInset,
                                                  bottom: sectionInset.bottom, right: endInset)
    case .vertical:
      collectionView?.contentInset = UIEdgeInsets(top: startInset, left: sectionInset.left,
                                                  bottom: endInset, right: sectionInset.right)
    }
    super.prepare()
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                         withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let collectionView = self.collectionView,
      let attributesForVisibleCells = self.layoutAttributesForElements(in: targetBounds(for: proposedContentOffset)) else {
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }

    let horizontal = self.scrollDirection == .horizontal
    let velocityValue = horizontal ? velocity.x : velocity.y
    let proposedStart = horizontal ? proposedContentOffset.x : proposedContentOffset.y
    let currentStart = horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y

    let cellsAttributes = attributesForVisibleCells.filter { $0.representedElementCategory == .cell }
    let candidateAttributes = closestAttributes(in: cellsAttributes, to: proposedStart)
    let currentAttributes = closestAttributes(in: cellsAttributes, to: currentStart)

    var targetAttributes = candidateAttributes
    if candidateAttributes?.indexPath == currentAttributes?.indexPath, velocityValue != 0.0,
      let attributes = candidateAttributes {
      let targetIndex = nextIndexPath(for: attributes.indexPath, forward: velocityValue > 0.0)
      targetAttributes = cellsAttributes.first(where: { $0.indexPath == targetIndex })
      if targetAttributes == nil {
        targetAttributes = layoutAttributesForItem(at: targetIndex)
      }
    }

    if let attributes = targetAttributes {
      return targetOffset(to: attributes, for: proposedContentOffset)
    }
    return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    if self.collectionView != nil {
      return targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: CGPoint.zero)
    }
    return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
  }
}

private extension AutoAlignedCollectionViewLayout {

  func nextIndexPath(for index: IndexPath, forward: Bool) -> IndexPath {
    guard let collectionView = collectionView else { return index }
    if forward {
      if (index.item + 1) < collectionView.numberOfItems(inSection: index.section) {
        return IndexPath(item: index.item + 1, section: index.section)
      } else if (index.section + 1) < collectionView.numberOfSections {
        return IndexPath(item: 0, section: index.section + 1)
      } else {
        return index
      }
    } else {
      if index.item > 0 {
        return IndexPath(item: index.item - 1, section: index.section)
      } else if index.section > 0 {
        return IndexPath(item: 0, section: index.section - 1)
      } else {
        return index
      }
    }
  }

  func closestAttributes(in cellsAttributes: [UICollectionViewLayoutAttributes], to offset: CGFloat) -> UICollectionViewLayoutAttributes? {
    guard let collectionView = collectionView else { return nil }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height

    var adjustedOffset: CGFloat
    switch settings.alignment {
    case .start:
      adjustedOffset = offset
    case .end:
      adjustedOffset = offset + area
    case .center:
      adjustedOffset = offset + 0.5 * area
    }

    adjustedOffset += settings.inset

    var candidateAttributes = cellsAttributes.first
    var candidateDistance = distance(from: candidateAttributes, to: adjustedOffset)

    cellsAttributes.forEach { attributes in
      let distance = self.distance(from: attributes, to: adjustedOffset)
      if distance < candidateDistance {
        candidateDistance = distance
        candidateAttributes = attributes
      }
    }

    return candidateAttributes
  }

  func targetBounds(for proposedOffset: CGPoint) -> CGRect {
    guard let collectionView = self.collectionView else {
      return .zero
    }
    let bounds = collectionView.bounds
    let contentOffset = collectionView.contentOffset
    switch settings.target {
    case .closest:
      return bounds
    case .factor(let factor):
      let horizontalOffset = bounds.width * 0.5 + CGFloat(factor) * bounds.width * 0.5
      let verticalOffset = bounds.height * 0.5 + CGFloat(factor) * bounds.height * 0.5
      let adjustedOffset: CGPoint
      switch scrollDirection {
      case .horizontal:
        adjustedOffset = CGPoint(x: contentOffset.x + CGFloat(factor) * (proposedOffset.x - contentOffset.x), y: proposedOffset.y)
      case .vertical:
        adjustedOffset = CGPoint(x: proposedOffset.x, y: contentOffset.y + CGFloat(factor) * (proposedOffset.y - contentOffset.y))
      }

      let target: CGRect
      switch scrollDirection {
      case .horizontal:
        target = CGRect(x: adjustedOffset.x - horizontalOffset, y: adjustedOffset.y, width: 2.0 * horizontalOffset, height: bounds.height)
      case .vertical:
        target = CGRect(x: adjustedOffset.x, y: adjustedOffset.y - verticalOffset, width: bounds.width, height: 2.0 * verticalOffset)
      }
      return target
    }
  }

  func targetOffset(to attributes: UICollectionViewLayoutAttributes, for proposedContentOffset: CGPoint) -> CGPoint {
    guard let collectionView = collectionView else { return .zero }
    var offset: CGFloat
    let horizontal = scrollDirection == .horizontal
    let area = horizontal ? collectionView.frame.width : collectionView.frame.height
    switch settings.alignment {
    case .start:
      offset = horizontal ? attributes.frame.minX : attributes.frame.minY
    case .end:
      offset = (horizontal ? attributes.frame.maxX : attributes.frame.maxY) - area
    case .center:
      offset = (horizontal ? attributes.frame.midX : attributes.frame.midY) - 0.5 * area
    }

    offset -= settings.inset

    if horizontal {
      return CGPoint(x: offset, y: proposedContentOffset.y)
    } else {
      return CGPoint(x: proposedContentOffset.x, y: offset)
    }
  }

  func distance(from layoutAttributes: UICollectionViewLayoutAttributes?, to offset: CGFloat) -> Float {
    guard let layoutAttributes = layoutAttributes else {
      return Float.infinity
    }
    let horizontal = scrollDirection == .horizontal
    let anchor: CGFloat
    switch settings.alignment {
    case .start:
      anchor = horizontal ? layoutAttributes.frame.minX : layoutAttributes.frame.minY
    case .end:
      anchor = horizontal ? layoutAttributes.frame.maxX : layoutAttributes.frame.maxY
    case .center:
      anchor = horizontal ? layoutAttributes.frame.midX : layoutAttributes.frame.midY
    }
    return fabsf(Float(anchor - offset))
  }

  var startInset: CGFloat {
    guard let collectionView = collectionView,
      let firstItemIndex = firstItemIndex else { return 0.0 }
    guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
      let firstItemSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: firstItemIndex) else {
        return 0.0
    }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height
    let size = scrollDirection == .horizontal ? firstItemSize.width : firstItemSize.height
    switch settings.alignment {
    case .start:
      return settings.inset
    case .end:
      return area - size + settings.inset
    case .center:
      return 0.5 * (area - size) + settings.inset
    }
  }

  var endInset: CGFloat {
    guard let collectionView = collectionView, let lastItemIndex = lastItemIndex else {
      return 0.0
    }
    guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
      let lastItemSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: lastItemIndex) else {
        return 0.0
    }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height
    let size = scrollDirection == .horizontal ? lastItemSize.width : lastItemSize.height
    switch settings.alignment {
    case .start:
      return (area - size) - settings.inset
    case .end:
      return -settings.inset
    case .center:
      return 0.5 * (area - size) - settings.inset
    }
  }

  var lastItemIndex: IndexPath? {
    guard let collectionView = collectionView else { return nil }
    let section = collectionView.numberOfSections - 1
    guard section >= 0, section < collectionView.numberOfSections else { return nil }
    let item = collectionView.numberOfItems(inSection: section) - 1
    guard item >= 0 else { return nil }
    return IndexPath(item: item, section: section)
  }

  var firstItemIndex: IndexPath? {
    guard let collectionView = collectionView else { return nil }
    let section = 0
    let item = 0
    guard section < collectionView.numberOfSections, collectionView.numberOfItems(inSection: section) > 0 else { return nil }
    return IndexPath(item: item, section: section)
  }
}
