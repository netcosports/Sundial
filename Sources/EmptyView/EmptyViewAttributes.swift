//
//  EmptyViewAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 7/4/19.
//

import UIKit
import RxSwift

open class EmptyViewAttributes<Data: Equatable>: UICollectionViewLayoutAttributes {

  public var data: Data?

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? EmptyViewAttributes<Data> else {
      return copy
    }
    typedCopy.data = data
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    guard let typedObject = object as? EmptyViewAttributes<Data> else {
      return false
    }

    return typedObject.data != self.data
  }
}
