//
//  TitleCollectionViewLayoutAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 11/16/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

open class TitleCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

  open var fade: CGFloat = 0

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? TitleCollectionViewLayoutAttributes else {
      return copy
    }

    typedCopy.fade = self.fade
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? TitleCollectionViewLayoutAttributes {
      if self.fade != other.fade {
        return false
      }
    }
    return true
  }
}
