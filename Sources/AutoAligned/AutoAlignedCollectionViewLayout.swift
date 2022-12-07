//
//  AutoAlignedCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 8/14/19.
//

import UIKit


open class AutoAlignedCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

  open var progress: CGFloat = 0

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? AutoAlignedCollectionViewLayoutAttributes else {
      return copy
    }

    typedCopy.progress = self.progress
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? AutoAlignedCollectionViewLayoutAttributes {
      if self.progress != other.progress {
        return false
      }
    }
    return true
  }
}


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
        
        @frozen
        public enum LayoutDirection {
            case ltr
            case rtl
            case auto
        }
        
        public let alignment: Alignment
        public let inset: CGFloat
        public let fillWithSideInsets: Bool
        public let target: ScrollTarget
        public let layoutDirection: LayoutDirection
        
        public init(
            alignment: Alignment,
            inset: CGFloat = 0.0,
            fillWithSideInsets: Bool = true,
            target: ScrollTarget = .closest,
            layoutDirection: LayoutDirection = .auto
        ) {
            self.alignment = alignment
            self.inset = inset
            self.fillWithSideInsets = fillWithSideInsets
            self.target = target
            self.layoutDirection = layoutDirection
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
            collectionView?.contentInset = UIEdgeInsets(
                top: sectionInset.top,
                left: startInset,
                bottom: sectionInset.bottom, right: endInset
            )
        case .vertical:
            collectionView?.contentInset = UIEdgeInsets(
                top: startInset,
                left: sectionInset.left,
                bottom: endInset,
                right: sectionInset.right
            )
    @unknown default: break
    }
    super.prepare()
  }

  open override class var layoutAttributesClass: AnyClass {
    return AutoAlignedCollectionViewLayoutAttributes.self
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
      guard  let collectionView = self.collectionView,
             let attributes = super.layoutAttributesForElements(in: rect) else {
          return nil
      }

    let horizontal = self.scrollDirection == .horizontal
    let offset = horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y
    let side = horizontal ? collectionView.frame.width : collectionView.frame.height
    let targetOffset: CGFloat
    switch getRealAlignment() {
    case .start:
      targetOffset = offset + settings.inset
    case .center:
      targetOffset = offset + settings.inset + 0.5 * side
    case .end:
      targetOffset = offset + settings.inset + side
    }
    attributes.compactMap { $0 as? AutoAlignedCollectionViewLayoutAttributes }
      .forEach { attributes in
      let currentItemOffset: CGFloat
      var size = horizontal ? attributes.frame.width : attributes.frame.height
      size += horizontal ? minimumInteritemSpacing : minimumLineSpacing
      guard size > 0.0 else { return }
      switch getRealAlignment() {
      case .start:
        currentItemOffset = horizontal ? attributes.frame.minX : attributes.frame.minY
      case .center:
        currentItemOffset = horizontal ? attributes.frame.midX : attributes.frame.midY
      case .end:
        currentItemOffset = horizontal ? attributes.frame.maxX : attributes.frame.maxY
      }
      let distance = abs(currentItemOffset - targetOffset)
      attributes.progress = max(0.0, 1.0 - distance / size)
    }
    return attributes
  }
    
    open override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        switch settings.layoutDirection {
        case .ltr:
            return isSystemRtl()
        case .rtl:
            return true
        case .auto:
            return isSystemRtl()
        }
    }
    
    private func isLayoutInRtl() -> Bool {
        switch settings.layoutDirection {
        case .ltr:
            return false
        case .rtl:
            return true
        case .auto:
            return isSystemRtl()
        }
    }
    
    private func isSystemRtl() -> Bool {
        guard let collectionView = self.collectionView else {
            return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        }
        return UIView.userInterfaceLayoutDirection(for: collectionView.semanticContentAttribute) == .rightToLeft
    }
    
    private func getRealAlignment() -> Settings.Alignment {
//        if scrollDirection != .horizontal {
//            return settings.alignment
//        }
//        switch settings.alignment {
//        case .start:
//            return isLayoutInRtl() ? .end : .start
//        case .center:
//            return .center
//        case .end:
//            return isLayoutInRtl() ? .start : .end
//        }
        
        return settings.alignment
    }
    
    open override var developmentLayoutDirection: UIUserInterfaceLayoutDirection {
        switch settings.layoutDirection {
        case .ltr:
            return isSystemRtl() ? .rightToLeft : .leftToRight
        case .rtl:
            return isSystemRtl() ? .leftToRight : .rightToLeft
        case .auto:
            return isLayoutInRtl() ? .leftToRight : .rightToLeft
        }
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
    if candidateAttributes?.indexPath == currentAttributes?.indexPath,
      velocityValue != 0.0, let attributes = candidateAttributes {
      var targetIndex = attributes.indexPath
      repeat {
        if let index = nextIndexPath(for: targetIndex, forward: velocityValue > 0.0) {
          targetIndex = index
        } else {
          break
        }
        targetAttributes = cellsAttributes.first(where: { $0.indexPath == targetIndex })
        if targetAttributes == nil {
          targetAttributes = layoutAttributesForItem(at: targetIndex)
        }
      } while !isSameLine(layoutAttributes: targetAttributes, with: attributes)
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

  func isSameLine(layoutAttributes: UICollectionViewLayoutAttributes?,
                  with anotherLayoutAttributes: UICollectionViewLayoutAttributes?) -> Bool {
    guard let lhs = layoutAttributes, let rhs = anotherLayoutAttributes else {
      return false
    }
    switch scrollDirection {
    case .horizontal:
      return lhs.frame.midX != rhs.frame.midX
    case .vertical:
      return lhs.frame.midY != rhs.frame.midY
    @unknown default:
      return false
    }
  }

  func nextIndexPath(for index: IndexPath, forward: Bool) -> IndexPath? {
    guard let collectionView = collectionView else { return nil }
    if forward {
      if (index.item + 1) < collectionView.numberOfItems(inSection: index.section) {
        return IndexPath(item: index.item + 1, section: index.section)
      } else if (index.section + 1) < collectionView.numberOfSections {
        return IndexPath(item: 0, section: index.section + 1)
      } else {
        return nil
      }
    } else {
      if index.item > 0 {
        return IndexPath(item: index.item - 1, section: index.section)
      } else if index.section > 0 {
        return IndexPath(item: 0, section: index.section - 1)
      } else {
        return nil
      }
    }
  }

  func closestAttributes(in cellsAttributes: [UICollectionViewLayoutAttributes], to offset: CGFloat) -> UICollectionViewLayoutAttributes? {
    guard let collectionView = collectionView else { return nil }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height

    var adjustedOffset: CGFloat
    switch getRealAlignment() {
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
      @unknown default:
        adjustedOffset = .zero
      }

      let target: CGRect
      switch scrollDirection {
      case .horizontal:
        target = CGRect(x: adjustedOffset.x - horizontalOffset, y: adjustedOffset.y, width: 2.0 * horizontalOffset, height: bounds.height)
      case .vertical:
        target = CGRect(x: adjustedOffset.x, y: adjustedOffset.y - verticalOffset, width: bounds.width, height: 2.0 * verticalOffset)
      @unknown default:
        target = .zero
      }
      return target
    }
  }

  func targetOffset(to attributes: UICollectionViewLayoutAttributes, for proposedContentOffset: CGPoint) -> CGPoint {
    guard let collectionView = collectionView else { return .zero }
    var offset: CGFloat
    let horizontal = scrollDirection == .horizontal
    let area = horizontal ? collectionView.frame.width : collectionView.frame.height
    switch getRealAlignment() {
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
    switch getRealAlignment() {
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
    guard settings.fillWithSideInsets, let collectionView = collectionView,
      let firstItemIndex = firstItemIndex else { return settings.inset }
    guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
      let firstItemSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: firstItemIndex) else {
        return settings.inset
    }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height
    let size = scrollDirection == .horizontal ? firstItemSize.width : firstItemSize.height
    switch getRealAlignment() {
    case .start:
      return settings.inset
    case .end:
      return area - size + settings.inset
    case .center:
      return 0.5 * (area - size) + settings.inset
    }
  }

  var endInset: CGFloat {
    guard settings.fillWithSideInsets, let collectionView = collectionView, let lastItemIndex = lastItemIndex else {
      return settings.inset
    }
    guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
      let lastItemSize = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: lastItemIndex) else {
        return settings.inset
    }
    let area = scrollDirection == .horizontal ? collectionView.frame.width : collectionView.frame.height
    let size = scrollDirection == .horizontal ? lastItemSize.width : lastItemSize.height
    switch getRealAlignment() {
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
