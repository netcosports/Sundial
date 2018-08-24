//
//  PreparedLayout.swift
//  Alidade
//
//  Created by Dmitry Duleba on 8/24/18.
//

import RxSwift
import RxCocoa

public protocol PreparedLayout {

  var readyObservable: Observable<Void> { get }

}

// MARK: - Rx

public extension Reactive where Base: PreparedLayout {

  var ready: ControlEvent<Void> {
    return ControlEvent(events: base.readyObservable)
  }

}
