//
//  EmptyViewAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 7/4/19.
//

import UIKit
import RxSwift

open class EmptyViewAttributes: UICollectionViewLayoutAttributes {

  public var reloadSubject: PublishSubject<Void>?

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? EmptyViewAttributes else {
      return copy
    }
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    return true
  }
}
