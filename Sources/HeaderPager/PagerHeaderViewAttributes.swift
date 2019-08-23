//
//  PagerHeaderViewAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 08/23/19.
//  Copyright © 2019 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

open class PagerHeaderViewAttributes: UICollectionViewLayoutAttributes, PagerHeaderAttributes {

  public var settings: Settings?
  public var invalidateTabFrames = false
  public var selectionClosure: ((Int) -> Void)?
  public weak var hostPagerSource: CollectionViewSource?

  open override var frame: CGRect {
    get { return super.frame }
    set {
      if super.frame != newValue {
        invalidateTabFrames = true
      }
      super.frame = newValue
    }
  }

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? PagerHeaderViewAttributes else {
      return copy
    }

    typedCopy.settings = self.settings
    typedCopy.invalidateTabFrames = self.invalidateTabFrames
    typedCopy.selectionClosure = self.selectionClosure
    typedCopy.hostPagerSource = hostPagerSource

    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? PagerHeaderViewAttributes {
      if self.settings != other.settings || self.invalidateTabFrames != other.invalidateTabFrames  {
        return false
      }
    }

    return true
  }
}
