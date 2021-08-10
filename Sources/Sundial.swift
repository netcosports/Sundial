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
  var active: Bool { get }
}

public extension Titleable {
  var id: String { return title }
  var active: Bool { return true }
}

// MARK: - Indicatorable

public protocol Indicatorable {
  var indicatorColor: UIColor { get }
}

public typealias ViewModelable = Titleable & Indicatorable

// MARK: - Selectable

public protocol Selectable: AnyObject {
  var selectedItem: ControlProperty<Int> { get }

  func select(item: Int, animated: Bool)
}

extension CollectionViewReusedPagerSource: Selectable {

  // FIXME: 
  public var selectedItem: ControlProperty<Int> { fatalError() }

  public func select(item: Int, animated: Bool) {
    (self.containerView?.collectionViewLayout as? PlainCollectionViewLayout<Self>)?.select(item: item, animated: animated)
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

public enum Anchor: Equatable {
  case content(Distribution)
  case centered
  case fillEqual
  case equal(size: CGFloat)
  case left(offset: CGFloat)
  case right(offset: CGFloat)
}

// MARK: - PagerHeaderSupplementaryAlignment

public enum PagerHeaderSupplementaryAlignment: Equatable {
  case top
  case bottom
  case topOffset(behaviorRelay: BehaviorRelay<CGFloat>)

  public static func == (lhs: PagerHeaderSupplementaryAlignment, rhs: PagerHeaderSupplementaryAlignment) -> Bool {
    switch (lhs, rhs) {
    case (.top, .top):
      return true
    case (.topOffset(let lBehaviorRelay), .topOffset(let rBehaviorRelay)):
      return lBehaviorRelay === rBehaviorRelay
    case (.bottom, .bottom):
      return true
    default: return false
    }
  }
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

// MARK: - Prepared

public protocol PreparedLayout {

  var readyObservable: Observable<Void> { get }
}

public extension Reactive where Base: PreparedLayout {

  var ready: ControlEvent<Void> {
    return ControlEvent(events: base.readyObservable)
  }
}


// MARK: - Settings

public struct Settings: Equatable {
  public var stripHeight: CGFloat
  public var markerHeight: CGFloat
  public var itemMargin: CGFloat
  public var stripInsets: UIEdgeInsets
  public var backgroundColor: UIColor
  public var anchor: Anchor
  public var inset: UIEdgeInsets
  public var alignment: PagerHeaderSupplementaryAlignment
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
  public var numberOfTitlesWhenHidden: Int
  public var pagerIndependentScrolling: Bool

  public init(stripHeight: CGFloat = 80.0,
              markerHeight: CGFloat = 5.5,
              itemMargin: CGFloat = 12.0,
              stripInsets: UIEdgeInsets = .zero,
              backgroundColor: UIColor = .clear,
              anchor: Anchor = .centered,
              inset: UIEdgeInsets = .zero,
              alignment: PagerHeaderSupplementaryAlignment = .top,
              pagesOnScreen: Int = 1,
              jumpingPolicy: JumpingPolicy = .disabled,
              shouldKeepFocusOnBoundsChange: Bool = false,
              numberOfTitlesWhenHidden: Int = 0,
              pagerIndependentScrolling: Bool = false) {
    self.stripHeight = stripHeight
    self.markerHeight = markerHeight
    self.itemMargin = itemMargin
    self.stripInsets = stripInsets
    self.backgroundColor = backgroundColor
    self.anchor = anchor
    self.inset = inset
    self.alignment = alignment
    assert(pagesOnScreen > 0, "number of pages on screen should be greater than 0")
    self.pagesOnScreen = pagesOnScreen
    assert(jumpingPolicy == .disabled || pagesOnScreen == 1, "jumping policy doesn't support 2+ pages currently")
    self.jumpingPolicy = jumpingPolicy
    self.shouldKeepFocusOnBoundsChange = shouldKeepFocusOnBoundsChange
    self.numberOfTitlesWhenHidden = numberOfTitlesWhenHidden
    self.pagerIndependentScrolling = pagerIndependentScrolling
  }
}
