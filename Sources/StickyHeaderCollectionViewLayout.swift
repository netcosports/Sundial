//
//  StickyHeaderCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 4/24/19.
//

import UIKit

public class StickyHeaderCollectionViewLayout: UICollectionViewFlowLayout {

  public struct Settings {
    public var minHeight: CGFloat
    public var sticky: Bool

    public init(sticky: Bool = false, minHeight: CGFloat = 0.0) {
      self.minHeight = minHeight
      self.sticky = sticky
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

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let topIndexPath = IndexPath(item: 0, section: 0)
    guard var layoutAttributes = super.layoutAttributesForElements(in: rect)?
      .filter({ $0.indexPath != topIndexPath }) else {
        return nil
    }
    guard let collectionView = collectionView, let dataSource = collectionView.dataSource else {
      return layoutAttributes
    }
    guard dataSource.numberOfSections!(in: collectionView) > 0,
      dataSource.collectionView(collectionView, numberOfItemsInSection: 0) > 0 else {
      return layoutAttributes
    }
    guard let topItem = self.layoutAttributesForItem(at: topIndexPath) else {
      return layoutAttributes
    }
    let offset = collectionView.contentOffset.y
    var originY = offset
    var height = topItem.frame.height - offset
    if !settings.sticky && height < settings.minHeight {
      originY = offset - (settings.minHeight - height)
    }
    if height < settings.minHeight {
      height = settings.minHeight
    }
    let size = CGSize(width: topItem.frame.width, height: height)
    let frame = CGRect(origin: CGPoint(x: 0.0, y: originY), size: size)
    topItem.frame = frame
    topItem.zIndex = Int.max
    if rect.intersects(topItem.frame) {
      layoutAttributes.insert(topItem, at: 0)
    }
    return layoutAttributes
  }
}
