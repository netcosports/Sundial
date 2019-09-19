//
//  StickyHeaderCollectionViewLayoutAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 4/29/19.
//

import UIKit

open class StickyHeaderCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

  open var progress: CGFloat = 0

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? StickyHeaderCollectionViewLayoutAttributes else {
      return copy
    }

    typedCopy.progress = self.progress
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? StickyHeaderCollectionViewLayoutAttributes {
      if self.progress != other.progress {
        return false
      }
    }
    return true
  }
}
