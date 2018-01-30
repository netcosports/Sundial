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
  weak var hostPagerSource: CollectionViewSource?  { get set }
}

public let DecorationViewId = "DecorationView"

public protocol DecorationViewPageable {

  associatedtype TitleCell: CollectionViewCell, Reusable
  associatedtype MarkerCell: CollectionViewCell
  associatedtype Attributes: UICollectionViewLayoutAttributes, Attributable where TitleCell.Data == Attributes.TitleViewModel
}

public protocol CollapsingItem: class {

  var scrollView: UIScrollView { get }
  var visible: Variable<Bool> { get }
  var extraInset: UIEdgeInsets { get }
}

public extension CollapsingItem {

  var extraInset: UIEdgeInsets {
    return .zero
  }
}
