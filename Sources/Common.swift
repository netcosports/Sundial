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

public protocol Attributable: class {

  associatedtype TitleViewModel: Titleable

  var titles: [TitleViewModel] { get set }
  var selectionClosure: ((Int) -> Void)?  { get set }
  var settings: Settings?  { get set }
  var hostPagerSource: CollectionViewSource?  { get set }
//  var invalidateTabFrames: Bool { get set }
//  var newCollectionViewWidth: CGFloat? { get set }

}

public let DecorationViewId = "DecorationView"

public protocol DecorationViewPageable {

  associatedtype TitleCell: CollectionViewCell, Reusable
  associatedtype MarkerCell: CollectionViewCell
  associatedtype Attributes: UICollectionViewLayoutAttributes, Attributable where TitleCell.Data == Attributes.TitleViewModel
}

public protocol CollapsingItem: class {

  var scrollView: UIScrollView { get }
  var visible: BehaviorRelay<Bool> { get }
  var extraInset: UIEdgeInsets { get }

  func headerHeightDidChange(_ height: CGFloat)

}

public extension CollapsingItem {

  var extraInset: UIEdgeInsets {
    return .zero
  }

  func headerHeightDidChange(_ height: CGFloat) {
  }

}
