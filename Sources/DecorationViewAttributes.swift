//
//  DecorationViewAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 5/31/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

open class DecorationViewAttributes<TitleViewModel: Titleable>: UICollectionViewLayoutAttributes, Attributable {

  public var titles: [TitleViewModel] = []
  public var selectionClosure: ((Int) -> Void)?
  public var settings: Settings?
  public weak var hostPagerSource: CollectionViewSource?

  public var invalidateTabFrames = false
  public var newCollectionViewWidth: CGFloat?

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? DecorationViewAttributes else {
      return copy
    }

    typedCopy.titles = self.titles
    typedCopy.hostPagerSource = self.hostPagerSource
    typedCopy.selectionClosure = self.selectionClosure
    typedCopy.settings = self.settings
    typedCopy.invalidateTabFrames = self.invalidateTabFrames
    typedCopy.newCollectionViewWidth = self.newCollectionViewWidth

    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? DecorationViewAttributes {
      if self.titles.map({ $0.title }) != other.titles.map({ $0.title }) {
        return false
      }
    }

    return true
  }
}
