//
//  StickyHeaderCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 4/24/19.
//

import UIKit

open class StickyHeaderCollectionViewLayout: EmptyViewCollectionViewLayout {

  public struct Settings {
    public var collapsing: Bool
    public var minHeight: CGFloat
    public var sticky: Bool
    public var alignToEdges: Bool

    public init(collapsing: Bool = true, sticky: Bool = false, minHeight: CGFloat = 0.0, alignToEdges: Bool = false) {
      self.minHeight = minHeight
      self.sticky = sticky
      self.alignToEdges = alignToEdges
      self.collapsing = collapsing
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

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let topIndexPath = IndexPath(item: 0, section: 0)
    guard let allLayoutAttributes = super.layoutAttributesForElements(in: rect) else {
      return nil
    }
    var layoutAttributes = allLayoutAttributes.filter({ $0.indexPath != topIndexPath })
    guard settings.collapsing else { return allLayoutAttributes }
    guard let collectionView = collectionView, let dataSource = collectionView.dataSource else {
      return layoutAttributes
    }
    guard dataSource.numberOfSections!(in: collectionView) > 0,
      dataSource.collectionView(collectionView, numberOfItemsInSection: 0) > 0 else {
        return layoutAttributes
    }
    guard let topLayoutAttributes = self.layoutAttributesForItem(at: topIndexPath) else {
      return layoutAttributes
    }
    let offset = collectionView.contentOffset.y
    var originY = offset
    var height = topLayoutAttributes.frame.height - offset
    if !settings.sticky && height < settings.minHeight {
      originY = offset - (settings.minHeight - height)
    }
    if height < settings.minHeight {
      height = settings.minHeight
    }
    let size = CGSize(width: topLayoutAttributes.frame.width, height: height)
    let frame = CGRect(origin: CGPoint(x: 0.0, y: originY), size: size)
    let stickyLayoutAttributes = StickyHeaderCollectionViewLayoutAttributes(forCellWith: topIndexPath)
    stickyLayoutAttributes.frame = frame
    stickyLayoutAttributes.zIndex = Int.max
    stickyLayoutAttributes.progress = (height - settings.minHeight) / (topLayoutAttributes.frame.height - settings.minHeight)
    stickyLayoutAttributes.alpha = topLayoutAttributes.alpha
    stickyLayoutAttributes.transform3D = topLayoutAttributes.transform3D
    stickyLayoutAttributes.isHidden = topLayoutAttributes.isHidden
    if rect.intersects(stickyLayoutAttributes.frame) {
      layoutAttributes.insert(stickyLayoutAttributes, at: 0)
    }
    return layoutAttributes
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    if !settings.alignToEdges {
      return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    return targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: CGPoint.zero)
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    if !settings.alignToEdges {
      return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
    guard let collectionView = collectionView, let dataSource = collectionView.dataSource else {
      return proposedContentOffset
    }
    guard dataSource.numberOfSections!(in: collectionView) > 0,
      dataSource.collectionView(collectionView, numberOfItemsInSection: 0) > 0 else {
        return proposedContentOffset
    }
    let topIndexPath = IndexPath(item: 0, section: 0)
    guard let topLayoutAttributes = self.layoutAttributesForItem(at: topIndexPath) else {
      return proposedContentOffset
    }
    let top: CGFloat = 0.0
    let bottom: CGFloat = topLayoutAttributes.frame.height - (settings.sticky ? settings.minHeight : 0.0)
    if top < proposedContentOffset.y && proposedContentOffset.y < bottom {
      let topDisance = abs(proposedContentOffset.y - top)
      let bottomDisance = abs(proposedContentOffset.y - bottom)
      if topDisance > bottomDisance {
        return CGPoint(x: proposedContentOffset.x, y: bottom)
      } else {
        return CGPoint(x: proposedContentOffset.x, y: top)
      }
    }

    return proposedContentOffset
  }
}
