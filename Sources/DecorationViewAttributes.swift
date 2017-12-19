//
//  DecorationViewAttributes.swift
//  PSGOneApp
//
//  Created by Sergei Mikhan on 5/31/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

class DecorationViewAttributes<TitleViewModel: Titleable>: UICollectionViewLayoutAttributes {

  var titles: [TitleViewModel] = []
  var backgroundColor: UIColor = .clear
  var selectionClosure: ((Int) -> Void)?
  var settings: Settings?
  weak var hostPagerSource: CollectionViewSource?

  override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? DecorationViewAttributes else {
      return copy
    }

    typedCopy.titles = self.titles
    typedCopy.hostPagerSource = self.hostPagerSource
    typedCopy.backgroundColor = self.backgroundColor
    typedCopy.selectionClosure = self.selectionClosure
    typedCopy.settings = self.settings
    return typedCopy
  }

  override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? DecorationViewAttributes {
      if self.titles.map({ $0.title }) != other.titles.map({ $0.title }) {
        return false
      }
//      else if self.titles.map({ $0.indicatorColor }) != other.titles.map({ $0.indicatorColor }) {
//        return false
//      } else if self.backgroundColor != other.backgroundColor {
//        return false
//      }
    }

    return true
  }
}
