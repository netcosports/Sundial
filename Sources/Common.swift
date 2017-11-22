//
//  Common.swift
//  Sundial
//
//  Created by Sergei Mikhan on 10/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

public protocol Titleable {
  var title: String { get }
}

public protocol Indicatorable {
  var indicatorColor: UIColor { get }
}

public typealias ViewModelable = Titleable & Indicatorable

public protocol Selectable: class {
  var selectedItem: ControlProperty<Int> { get }
}

extension CollectionViewPagerSource: Selectable {
  public var selectedItem: ControlProperty<Int> { return rx.selectedItem }
}

extension CollectionViewReusedPagerSource: Selectable {
  public var selectedItem: ControlProperty<Int> { return rx.selectedItem }
}

public typealias Progress = (page: Int, progress: CGFloat)

public enum Anchor {
  case content
  case centered
  case fillEqual
  case equal(size: CGFloat)
  case left(offset: CGFloat)
  case right(offset: CGFloat)
}

public enum DecorationAlignment {
  case top
  case topOffset(variable: Variable<CGFloat>)
}

public struct Settings {
  let stripHeight: CGFloat
  let markerHeight: CGFloat
  let itemMargin: CGFloat
  let bottomStripSpacing: CGFloat
  let anchor: Anchor
  let inset: UIEdgeInsets
  let alignment: DecorationAlignment

  public init(stripHeight: CGFloat = 80.0,
              markerHeight: CGFloat = 5.5,
              itemMargin: CGFloat = 12.0,
              bottomStripSpacing: CGFloat = 0.0,
              anchor: Anchor = .centered,
              inset: UIEdgeInsets = .zero,
              alignment: DecorationAlignment = .top) {
    self.stripHeight = stripHeight
    self.markerHeight = markerHeight
    self.itemMargin = itemMargin
    self.bottomStripSpacing = bottomStripSpacing
    self.anchor = anchor
    self.inset = inset
    self.alignment = alignment
  }
}
