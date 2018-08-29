//
//  Sundial.swift
//  Sundial
//
//  Created by Sergei Mikhan on 30/01/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

// MARK: - Titleable

public protocol Titleable {
  var title: String { get }
  var id: String { get }
}

public extension Titleable {
  var id: String { return title }
}

// MARK: - Indicatorable

public protocol Indicatorable {
  var indicatorColor: UIColor { get }
}

public typealias ViewModelable = Titleable & Indicatorable

// MARK: - Selectable

public protocol Selectable: class {
  var selectedItem: ControlProperty<Int> { get }

  func select(item: Int, animated: Bool)
}

extension CollectionViewPagerSource: Selectable {

  public var selectedItem: ControlProperty<Int> { return rx.selectedItem }

  public func select(item: Int, animated: Bool) {
    (self.containerView?.collectionViewLayout as? PlainCollectionViewLayout)?.select(item: item, animated: animated)
  }
}

extension CollectionViewReusedPagerSource: Selectable {

  public var selectedItem: ControlProperty<Int> { return rx.selectedItem }

  public func select(item: Int, animated: Bool) {
    (self.containerView?.collectionViewLayout as? PlainCollectionViewLayout)?.select(item: item, animated: animated)
  }
}

// MARK: - Progress

public struct Progress: Equatable {
  public let pages: CountableClosedRange<Int>
  public let progress: CGFloat

  public static func == (lhs: Progress, rhs: Progress) -> Bool {
    return lhs.pages == rhs.pages && lhs.progress == rhs.progress
  }
}

extension CountableClosedRange where Bound == Int {

  var next: CountableClosedRange<Int> {
    return lowerBound.advanced(by: 1)...upperBound.advanced(by: 1)
  }
}

// MARK: - Distribution

public enum Distribution {
  case left, right, center, proportional, inverseProportional, equalSpacing
}

// MARK: - Anchor

public enum Anchor {
  case content(Distribution)
  case centered
  case fillEqual
  case equal(size: CGFloat)
  case left(offset: CGFloat)
  case right(offset: CGFloat)
}

// MARK: - DecorationAlignment

public enum DecorationAlignment {
  case top
  case topOffset(behaviorRelay: BehaviorRelay<CGFloat>)
}

// MARK: - JumpingPolicy

public enum JumpingPolicy: Equatable {
  case disabled
  case skip(pages: Int)

  public static func == (lhs: JumpingPolicy, rhs: JumpingPolicy) -> Bool {
    switch (lhs, rhs) {
    case (.disabled, .disabled): return true
    case (.skip(let lhs), .skip(let rhs)): return lhs == rhs
    default: return false
    }
  }
}

// MARK: - Settings

public struct Settings {
  public var stripHeight: CGFloat
  public var markerHeight: CGFloat
  public var itemMargin: CGFloat
  public var bottomStripSpacing: CGFloat
  public var backgroundColor: UIColor
  public var anchor: Anchor
  public var inset: UIEdgeInsets
  public var alignment: DecorationAlignment
  public var pagesOnScreen: Int {
    willSet {
      assert(newValue > 0, "number of pages on screen should be greater than 0")
    }
  }
  public var jumpingPolicy: JumpingPolicy {
    willSet {
      assert(newValue == .disabled || pagesOnScreen == 1, "jumping policy doesn't support 2+ pages currently")
    }
  }
  public var shouldKeepFocusOnBoundsChange: Bool

  public init(stripHeight: CGFloat = 80.0,
              markerHeight: CGFloat = 5.5,
              itemMargin: CGFloat = 12.0,
              bottomStripSpacing: CGFloat = 0.0,
              backgroundColor: UIColor = .clear,
              anchor: Anchor = .centered,
              inset: UIEdgeInsets = .zero,
              alignment: DecorationAlignment = .top,
              pagesOnScreen: Int = 1,
              jumpingPolicy: JumpingPolicy = .disabled,
              shouldKeepFocusOnBoundsChange: Bool = false) {
    self.stripHeight = stripHeight
    self.markerHeight = markerHeight
    self.itemMargin = itemMargin
    self.bottomStripSpacing = bottomStripSpacing
    self.backgroundColor = backgroundColor
    self.anchor = anchor
    self.inset = inset
    self.alignment = alignment
    assert(pagesOnScreen > 0, "number of pages on screen should be greater than 0")
    self.pagesOnScreen = pagesOnScreen
    assert(jumpingPolicy == .disabled || pagesOnScreen == 1, "jumping policy doesn't support 2+ pages currently")
    self.jumpingPolicy = jumpingPolicy
    self.shouldKeepFocusOnBoundsChange = shouldKeepFocusOnBoundsChange
  }
}

public typealias DecorationView = GenericDecorationView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.Data>, DecorationViewAttributes<TitleCollectionViewCell.Data>>
public typealias CollectionViewLayout = GenericCollectionViewLayout<DecorationView>
public typealias CollapsingCollectionViewLayout = GenericCollapsingCollectionViewLayout<DecorationView>
