//
//  MarkerDecorationView.swift
//  Sundial
//
//  Created by Sergei Mikhan on 10/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

open class MarkerDecorationAttributes<TitleViewModel: ViewModelable, MarkerCell: CollectionViewCell>: UICollectionViewLayoutAttributes, Markerable {

  public typealias ViewModel = TitleViewModel
  open func apply(currentTitle: ViewModel?, nextTitle: ViewModel?, progress: CGFloat) {
    if let currentTitle = currentTitle, let nextTitle = nextTitle {
      color = currentTitle.indicatorColor.blended(with: nextTitle.indicatorColor, progress: progress)
    } else if let currentTitle = currentTitle {
      color = currentTitle.indicatorColor
    } else {
      color = .clear
    }
  }

  open var color: UIColor = .clear

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? MarkerDecorationAttributes<TitleViewModel, MarkerCell> else {
      return copy
    }

    typedCopy.color = self.color
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? MarkerDecorationAttributes<TitleViewModel, MarkerCell> {
      if self.color != other.color {
        return false
      }
    }
    return true
  }
}

let MarkerDecorationViewId = "MarkerDecorationView"

open class MarkerDecorationView<TitleViewModel: ViewModelable>: CollectionViewCell {

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    if let layoutAttributes = layoutAttributes as? MarkerDecorationAttributes<TitleViewModel, MarkerDecorationView<TitleViewModel>> {
      contentView.backgroundColor = layoutAttributes.color
    }
  }
}
