//
//  CollapsingHeaderViewAttributes.swift
//  Sundial
//
//  Created by Sergei Mikhan on 1/3/18.
//

import UIKit

public protocol Progressable: class {
  var progress: CGFloat { get }
}

public class CollapsingHeaderViewAttributes: UICollectionViewLayoutAttributes, Progressable {

  public var progress: CGFloat = 0.0

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? CollapsingHeaderViewAttributes else {
      return copy
    }

    typedCopy.progress = self.progress
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    if let other = object as? CollapsingHeaderViewAttributes {
      if self.progress != other.progress {
        return false
      }
    }

    return true
  }
}
