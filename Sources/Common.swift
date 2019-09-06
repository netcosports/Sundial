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

public protocol Markerable {
  associatedtype ViewModel: ViewModelable
  func apply(currentTitle: ViewModel?, nextTitle: ViewModel?, progress: CGFloat)
}

@available(*, deprecated, message: "Please use PagerHeaderCollectionViewLayout")
public protocol Attributable: class {

  associatedtype TitleViewModel: Titleable

  var titles: [TitleViewModel] { get set }
  var selectionClosure: ((Int) -> Void)?  { get set }
  var settings: Settings?  { get set }
  var hostPagerSource: CollectionViewSource?  { get set }
  var invalidateTabFrames: Bool { get set }
//  var newCollectionViewWidth: CGFloat? { get set }

}

@available(*, deprecated, message: "Please use PagerHeaderCollectionViewLayout")
public let DecorationViewId = "DecorationView"

@available(*, deprecated, message: "Please use PagerHeaderCollectionViewLayout")
public protocol DecorationViewPageable {

  associatedtype TitleCell: CollectionViewCell, Reusable
  associatedtype MarkerCell: CollectionViewCell
  associatedtype Attributes: UICollectionViewLayoutAttributes, Attributable where TitleCell.Data == Attributes.TitleViewModel
}

public protocol CollapsingItem: class {

  var scrollView: UIScrollView { get }
  var visible: BehaviorRelay<Bool> { get }
  var extraInset: UIEdgeInsets { get }
  // FIXME: move this to settings
  var followDirection: Bool { get }

  // FIXME: do we really need it here?
  // layout has relay for it
  func headerHeightDidChange(_ height: CGFloat)

}

public extension CollapsingItem {

  var extraInset: UIEdgeInsets {
    return .zero
  }

  var followDirection: Bool {
    return false
  }

  func headerHeightDidChange(_ height: CGFloat) {
  }

}
