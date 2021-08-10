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

public protocol CollapsingItem: AnyObject {

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
