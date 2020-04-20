//
//  PagerHeaderCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 08/23/19.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

public let PagerHeaderSupplementaryViewKind = "PagerHeaderSupplementaryViewKind"
public let PagerHeaderCollapsingSupplementaryViewKind = "PagerHeaderCollapsingSupplementaryViewKind"

open class PagerHeaderCollectionViewLayout: PlainCollectionViewLayout {

  public let minHeaderHeight = BehaviorRelay<CGFloat>(value: 0)
  public let maxHeaderHeight = BehaviorRelay<CGFloat>(value: 240)
  public let headerInset = BehaviorRelay<CGFloat>(value: 0)
  public let headerHeight = BehaviorRelay<CGFloat>(value: 120)
  public var expanded: Observable<Bool> { return expandedSubject.asObservable() }
  public let followOffsetChanges = BehaviorRelay<Bool>(value: false)

  // FIXME: move to settings?
  open class var headerZIndex: Int { return 1024 }

  static let headerIndex = IndexPath(index: 0)
  static let collapsingIndex = IndexPath(index: 0)

  fileprivate let expandedSubject = BehaviorSubject<Bool>(value: true)
  fileprivate var handlers: [CollapsingHeaderHandler] = []
  fileprivate var pengingCollapsingItems: [CollapsingItem] = []
  fileprivate weak var connectedItem: CollapsingItem?
  fileprivate var updateHeightDisposeBag: DisposeBag?
  fileprivate var updateMaxHeightDisposeBag: DisposeBag?
  fileprivate let collapsingItemSubject = PublishSubject<CollapsingItem>()

  public override init(hostPagerSource: Source, settings: Settings? = nil) {
    super.init(hostPagerSource: hostPagerSource, settings: settings)

    let observable: Observable<Void> = Observable.from([
      minHeaderHeight.asObservable().skip(1).distinctUntilChanged().map { _ in () },
      maxHeaderHeight.asObservable().skip(1).distinctUntilChanged().map { _ in () },
      headerInset.asObservable().skip(1).distinctUntilChanged().map { _ in () },
      headerHeight.asObservable().skip(1).distinctUntilChanged().map { _ in () },
    ]).merge()

    observable.subscribe(onNext: { [weak self] _ in
      self?.invalidateLayout()
    }).disposed(by: disposeBag)

    Observable.combineLatest(headerHeight.asObservable(), maxHeaderHeight.asObservable()) {
      Double($0) == Double($1)
    }.distinctUntilChanged().bind(to: expandedSubject).disposed(by: disposeBag)

    collapsingItemSubject.subscribe(onNext: { [weak self] collapsingItem in
      self?.append(collapsingItems: [collapsingItem])
    }).disposed(by: disposeBag)

    headerInset.accept(self.settings.stripHeight)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func prepare() {
    super.prepare()

    if hasCollapsingSupplementary && !pengingCollapsingItems.isEmpty {
      append(collapsingItems: pengingCollapsingItems)
      pengingCollapsingItems = []
    }
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let sourceAttributes = super.layoutAttributesForElements(in: rect) ?? []
    guard let collectionView = collectionView else { return sourceAttributes }
    guard collectionView.numberOfSections > 0 else { return sourceAttributes }
    var attributes = sourceAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
    addPagerHeaderAttributes(to: &attributes)
    addCollapsingHeaderAttributes(to: &attributes)
    addJumpAttributes(to: &attributes)
    return attributes
  }

  open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attributes = layoutAttributesForElements(in: .infinite) else { return nil }

    for attribute in attributes {
      if attribute.representedElementCategory == .cell && attribute.indexPath == indexPath {
        return attribute
      }
    }
    return nil
  }

  open override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                          at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    if elementKind == PagerHeaderSupplementaryViewKind, indexPath == PagerHeaderCollectionViewLayout.headerIndex {
      return pagerHeaderViewAttributes()
    }

    if elementKind == PagerHeaderCollapsingSupplementaryViewKind, indexPath == PagerHeaderCollectionViewLayout.collapsingIndex {
      return collapsingHeaderAttributes()
    }

    return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
  }

  open func pagerHeaderViewAttributes() -> PagerHeaderViewAttributes? {
    guard hasPagerSupplementary else { return nil }
    let pagerHeaderAttributes = PagerHeaderViewAttributes(forSupplementaryViewOfKind: PagerHeaderSupplementaryViewKind,
                                                          with: PagerHeaderCollectionViewLayout.headerIndex)
    pagerHeaderAttributes.zIndex = Int.max
    pagerHeaderAttributes.settings = self.settings
    pagerHeaderAttributes.hostPagerSource = hostPagerSource
    pagerHeaderAttributes.selectionClosure = { [weak self] in
      guard let self = self else { return }
      self.select(item: $0, jumpingPolicy: self.settings.jumpingPolicy)
    }
    pagerHeaderAttributes.frame = self.pagerHeaderFrame
    return pagerHeaderAttributes
  }

  open func collapsingHeaderAttributes() -> CollapsingHeaderViewAttributes? {
    guard hasCollapsingSupplementary else { return nil }

    let сollapsingHeaderViewAttributes = CollapsingHeaderViewAttributes(forSupplementaryViewOfKind: PagerHeaderCollapsingSupplementaryViewKind,
                                                                        with: PagerHeaderCollectionViewLayout.collapsingIndex)
    сollapsingHeaderViewAttributes.zIndex = type(of: self).headerZIndex

    guard let collectionView = collectionView else { return сollapsingHeaderViewAttributes }

    сollapsingHeaderViewAttributes.frame = CGRect(x: collectionView.contentOffset.x,
                                                   y: 0.0,
                                                   width: collectionView.frame.width,
                                                   height: headerHeight.value)
    if maxHeaderHeight.value == minHeaderHeight.value {
      сollapsingHeaderViewAttributes.progress = 0.0
    } else {
      сollapsingHeaderViewAttributes.progress = (headerHeight.value - minHeaderHeight.value) / (maxHeaderHeight.value - minHeaderHeight.value)
    }
    return сollapsingHeaderViewAttributes
  }

  open var pagerHeaderFrame: CGRect {
    guard let collectionView = collectionView else { return .zero }

    if hasCollapsingSupplementary {
      return CGRect(x: collectionView.contentOffset.x,
                    y: headerHeight.value,
                    width: collectionView.frame.width,
                    height: settings.stripHeight)
    }

    let topOffset: CGFloat
    switch settings.alignment {
    case .top:
      topOffset = 0.0
    case .topOffset(let variable):
      topOffset = variable.value
    }

    return CGRect(x: collectionView.contentOffset.x,
                  y: topOffset,
                  width: collectionView.frame.width,
                  height: settings.stripHeight)
  }

  open func scrollToTop() {
    if let connectedItem = connectedItem {
      let point = CGPoint(x: 0.0, y: -connectedItem.scrollView.contentInset.top)
      connectedItem.scrollView.setContentOffset(point, animated: true)

      followOffsetChanges.accept(true)
      let updateHeightDisposeBag = DisposeBag()
      connectedItem.scrollView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] in
        guard let `self` = self else { return }
        self.headerHeight.accept(self.maxHeaderHeight.value)
        self.updateHeightDisposeBag = nil
        self.followOffsetChanges.accept(false)
      }).disposed(by: updateHeightDisposeBag)
      self.updateHeightDisposeBag = updateHeightDisposeBag
    } else {
      guard let collectionView = collectionView, let cell = collectionView.visibleCells.first else { return }

      func verticallyOrientedContainerView(in views: [UIView], closure: (UIScrollView) -> Void) {
        for view in views {
          if let collectionView = view as? UICollectionView,
          (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .vertical {
            closure(collectionView)
          }
          if let tableView = view as? UITableView {
            closure(tableView)
          }
          verticallyOrientedContainerView(in: view.subviews, closure: closure)
        }
      }

      verticallyOrientedContainerView(in: cell.subviews) { containerView in
        containerView.setContentOffset(CGPoint(x: 0.0, y: -containerView.contentInset.top), animated: true)
      }
    }
  }

  open func update(maxHeight: CGFloat, animated: Bool = true) {
    guard let connectedItem = connectedItem else { return }
    guard connectedItem.scrollView.contentOffset.y < 0 else { return }

    let point = CGPoint(x: 0.0, y: -(maxHeight + settings.stripHeight))
    connectedItem.scrollView.setContentOffset(point, animated: animated)

    followOffsetChanges.accept(true)
    if self.maxHeaderHeight.value < maxHeight {
      maxHeaderHeight.accept(maxHeight)
    }

    let updateMaxHeightDisposeBag = DisposeBag()
    connectedItem.scrollView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] in
      guard let sself = self else { return }
      if sself.maxHeaderHeight.value > maxHeight {
        sself.maxHeaderHeight.accept(maxHeight)
      }
      sself.updateMaxHeightDisposeBag = nil
      sself.followOffsetChanges.accept(false)
    }).disposed(by: updateMaxHeightDisposeBag)
    self.updateMaxHeightDisposeBag = updateMaxHeightDisposeBag
  }

  open func update(height: CGFloat, animated: Bool = true) {
    guard let connectedItem = connectedItem else { return }
    guard connectedItem.scrollView.contentOffset.y < 0 else { return }

    let point = CGPoint(x: 0.0, y: -(height + settings.stripHeight))
    connectedItem.scrollView.setContentOffset(point, animated: animated)

    followOffsetChanges.accept(true)
    if self.headerHeight.value < height {
      headerHeight.accept(height)
    }

    let updateHeightDisposeBag = DisposeBag()
    connectedItem.scrollView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] in
      guard let `self` = self else { return }
      if self.headerHeight.value > height {
        self.headerHeight.accept(height)
      }
      self.updateHeightDisposeBag = nil
      self.followOffsetChanges.accept(false)
    }).disposed(by: updateHeightDisposeBag)
    self.updateHeightDisposeBag = updateHeightDisposeBag
  }

  open func append(collapsingItems: [CollapsingItem]) {
    guard hasCollapsingSupplementary else {
      pengingCollapsingItems.append(contentsOf: collapsingItems)
      return
    }
    let handlers: [CollapsingHeaderHandler] = collapsingItems.compactMap { item in
      guard !self.handlers.contains(where: { $0.collapsingItem === item }) else {
        return nil
      }
      return self.handler(for: item)
    }

    self.handlers = self.handlers + handlers
  }

}

extension PagerHeaderCollectionViewLayout {

  var hasPagerSupplementary: Bool {
    return hostPagerSource?.sections.first?.supplementaries(for: .custom(kind: PagerHeaderSupplementaryViewKind)).isEmpty == false
  }

  func adjustItem(frame: CGRect) -> CGRect {
    if hasCollapsingSupplementary {
      return frame
    }

    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  func addPagerHeaderAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > settings.numberOfTitlesWhenHidden else { return }
    guard let pagerHeaderViewAttributes = self.pagerHeaderViewAttributes() else { return }

    attributes.forEach {
      $0.frame = adjustItem(frame: $0.frame)
    }
    attributes.append(pagerHeaderViewAttributes)
  }
}

public extension Reactive where Base: PagerHeaderCollectionViewLayout {

  var collapsingItem: AnyObserver<CollapsingItem> {
    return base.collapsingItemSubject.asObserver()
  }
}


fileprivate extension PagerHeaderCollectionViewLayout {

  var hasCollapsingSupplementary: Bool {
    return hostPagerSource?.sections.first?.supplementaries(for: .custom(kind: PagerHeaderCollapsingSupplementaryViewKind)).isEmpty == false
  }

  func handler(for collapsingItem: CollapsingItem) -> CollapsingHeaderHandler {
    let handler = CollapsingHeaderHandler(with: collapsingItem,
                                          min: minHeaderHeight,
                                          max: maxHeaderHeight,
                                          headerInset: headerInset,
                                          headerHeight: headerHeight,
                                          followOffsetChanges: followOffsetChanges)

    collapsingItem.visible.asDriver().drive(onNext: { [weak handler, weak self] visible in
      guard let self = self else { return }
      if visible && self.hasCollapsingSupplementary {
        handler?.connect()
        self.connectedItem = collapsingItem
      } else {
        handler?.disconnect()
      }
    }).disposed(by: self.disposeBag)
    return handler
  }

  func addCollapsingHeaderAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > settings.numberOfTitlesWhenHidden else { return }
    guard let collapsingHeaderAttributes = self.collapsingHeaderAttributes() else { return }
    attributes.append(collapsingHeaderAttributes)
  }
}
