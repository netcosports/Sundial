//
//  CollapsingCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 11/21/17.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

open class GenericCollapsingCollectionViewLayout<DecorationView: CollectionViewCell>: GenericCollectionViewLayout<DecorationView>
where DecorationView: DecorationViewPageable, DecorationView.TitleCell.Data: Indicatorable {

  public let minHeaderHeight = Variable<CGFloat>(0)
  public let maxHeaderHeight = Variable<CGFloat>(240)
  public let headerInset = Variable<CGFloat>(0)
  public let headerHeight = Variable<CGFloat>(120)
  public var expanded: Observable<Bool> { return expandedSubject.asObservable() }
  public let followOffsetChanges = Variable<Bool>(false)

  open class var headerZIndex: Int { return 1024 }

  fileprivate let expandedSubject = BehaviorSubject<Bool>(value: true)
  fileprivate var handlers: [CollapsingHeaderHandler] = []
  fileprivate weak var connectedItem: CollapsingItem?
  fileprivate var updateMaxHeightDisposeBag: DisposeBag?

  public init(items: [CollapsingItem], hostPagerSource: Source, settings: Settings? = nil, pager: PagerClosure?) {
    super.init(hostPagerSource: hostPagerSource, settings: settings, pager: pager)
    self.handlers = items.flatMap { [weak self] item in
      return self?.handler(for: item)
    }

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

    headerInset.value = self.settings.stripHeight
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard var layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
    guard let collectionView = collectionView else { return layoutAttributes }
    guard collectionView.numberOfSections > 0 else { return layoutAttributes }

    crashIfHeaderPresent(in: layoutAttributes)

    let attributes = collapsingHeaderAttributes()
    layoutAttributes.append(attributes)

    return layoutAttributes
  }

  open func collapsingHeaderAttributes() -> CollapsingHeaderViewAttributes {
    let headerIndexPath = IndexPath(item: 0, section: 0)
    let сollapsingHeaderViewAttributes = CollapsingHeaderViewAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: headerIndexPath)
    сollapsingHeaderViewAttributes.zIndex = type(of: self).headerZIndex

    guard let collectionView = collectionView else { return сollapsingHeaderViewAttributes }

    сollapsingHeaderViewAttributes.frame = CGRect(x: collectionView.contentOffset.x,
                                                  y: 0.0,
                                                  width: collectionView.frame.width,
                                                  height: headerHeight.value)

    return сollapsingHeaderViewAttributes
  }

  open override var decorationFrame: CGRect {
    guard let collectionView = collectionView else { return .zero }

    return CGRect(x: collectionView.contentOffset.x,
                  y: headerHeight.value,
                  width: collectionView.frame.width,
                  height: settings.stripHeight)
  }

  open override func adjustItem(frame: CGRect) -> CGRect {
    return frame
  }

  open func update(maxHeight: CGFloat, animated: Bool = true) {
    guard let connectedItem = connectedItem else { return }
    guard connectedItem.scrollView.contentOffset.y < 0 else { return }

    let point = CGPoint(x: 0.0, y: -(maxHeight + settings.stripHeight))
    connectedItem.scrollView.setContentOffset(point, animated: true)

    followOffsetChanges.value = true
    if self.maxHeaderHeight.value < maxHeight {
      maxHeaderHeight.value = maxHeight
    }

    let updateMaxHeightDisposeBag = DisposeBag()
    connectedItem.scrollView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] in
      guard let sself = self else { return }
      if sself.maxHeaderHeight.value > maxHeight {
        sself.maxHeaderHeight.value = maxHeight
      }
      sself.updateMaxHeightDisposeBag = nil
      sself.followOffsetChanges.value = false
    }).disposed(by: updateMaxHeightDisposeBag)
    self.updateMaxHeightDisposeBag = updateMaxHeightDisposeBag
  }

  open func append(collapsingItems: [CollapsingItem]) {
    let handlers: [CollapsingHeaderHandler] = collapsingItems.flatMap { item in
      guard !self.handlers.contains(where: { $0.collapsingItem === item }) else {
        return nil
      }
      return self.handler(for: item)
    }

    self.handlers = self.handlers + handlers
  }

  fileprivate func handler(for collapsingItem: CollapsingItem) -> CollapsingHeaderHandler {
    let handler = CollapsingHeaderHandler(with: collapsingItem,
                                          min: minHeaderHeight,
                                          max: maxHeaderHeight,
                                          headerInset: headerInset,
                                          headerHeight: headerHeight,
                                          followOffsetChanges: followOffsetChanges)

    collapsingItem.visible.asDriver().drive(onNext: { [weak handler, weak self] visible in
      if visible {
        handler?.connect()
        self?.connectedItem = collapsingItem
      } else {
        handler?.disconnect()
      }
    }).disposed(by: self.disposeBag)
    return handler
  }

  fileprivate func crashIfHeaderPresent(in items: [UICollectionViewLayoutAttributes]) {
    for attributes in items {
      if attributes.representedElementCategory == .supplementaryView && attributes.representedElementKind == UICollectionElementKindSectionHeader {
        if attributes.size != .zero {
          fatalError("collapsing header size(for:, containerSize:) -> CGSize should return .zero")
        }
      }
    }
  }
}

class CollapsingHeaderHandler {

  let headerHeight: Variable<CGFloat>
  let minHeaderHeight: Variable<CGFloat>
  let maxHeaderHeight: Variable<CGFloat>
  let headerInset: Variable<CGFloat>
  let followOffsetChanges: Variable<Bool>

  fileprivate weak var collapsingItem: CollapsingItem?

  enum ConnectionStatus: Int {
    case none
    case connected
    case disconnected
  }

  private var connection: ConnectionStatus = .none
  private var activeDispose: Disposable?
  private var nonActiveDispose: Disposable?
  private let disposeBag = DisposeBag()

  init(with collapsingItem: CollapsingItem,
       min: Variable<CGFloat>,
       max: Variable<CGFloat>,
       headerInset: Variable<CGFloat>,
       headerHeight: Variable<CGFloat>,
       followOffsetChanges: Variable<Bool>) {

    self.collapsingItem = collapsingItem
    self.minHeaderHeight = min
    self.maxHeaderHeight = max
    self.headerHeight = headerHeight
    self.headerInset = headerInset
    self.followOffsetChanges = followOffsetChanges

    headerHeight.asDriver().drive(onNext: { [weak collapsingItem] height in
      collapsingItem?.headerHeightDidChange(height)
    }).disposed(by: disposeBag)

    let contentSizeDriver = collapsingItem.scrollView.rx
      .observe(CGSize.self, #keyPath(UICollectionView.contentSize))
      .asDriver(onErrorJustReturn: nil)
      .filter { $0?.width != 0.0 && $0?.height != 0.0 }
      .distinctUntilChanged { $0?.height == $1?.height }

    Driver.combineLatest(contentSizeDriver, maxHeaderHeight.asDriver())
      .drive(onNext: { [weak collapsingItem = self.collapsingItem, weak self] contentSize, maxHeight in
      guard let contentSize = contentSize else { return }
      guard let sself = self else { return }
      guard let collapsingItem = collapsingItem else { return }

      let extraInset = collapsingItem.extraInset
      let topInset = maxHeight + sself.headerInset.value + extraInset.top
      var bottomInset: CGFloat = collapsingItem.scrollView.frame.height - (contentSize.height + sself.minHeaderHeight.value + sself.headerInset.value + extraInset.bottom)
      if bottomInset < 0.0  {
        bottomInset = extraInset.bottom
      }

      let contentOffsetOriginal = collapsingItem.scrollView.contentOffset
      let adjustedY = -(sself.headerHeight.value + sself.headerInset.value)
      let contentOffset = CGPoint(x: contentOffsetOriginal.x, y: adjustedY)

      collapsingItem.scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
      collapsingItem.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
      collapsingItem.scrollView.contentOffset = contentOffset
    }).disposed(by: disposeBag)
  }

  func connect() {
    guard connection != .connected else { return }
    connection = .connected

    guard let collapsingItem = collapsingItem else { return }
    let targetContentOffset = -headerHeight.value - headerInset.value
    if collapsingItem.scrollView.contentOffset.y < targetContentOffset {
      collapsingItem.scrollView.contentOffset = CGPoint(x: 0, y: targetContentOffset)
    }
    activeDispose?.dispose()
    nonActiveDispose?.dispose()

    let headerHeightDispose = collapsingItem.scrollView.rx.contentOffset
      .asObservable()
      .skip(1)
      .distinctUntilChanged()
      .filter { [weak self] _ in
        guard let `self` = self else { return false }
        let scrollView = collapsingItem.scrollView

        let isScrollingToTop = scrollView.responds(to: NSSelectorFromString("_isScrollingToTop"))
          ? scrollView._isScrollingToTop
          : false

        return scrollView.panGestureRecognizer.state != .possible
          || scrollView.isDecelerating
          || scrollView.isDragging
          || scrollView.isTracking
          || isScrollingToTop
          || self.followOffsetChanges.value != false
      }
      .map { [unowned self] in
        return min(max(self.minHeaderHeight.value, -$0.y - self.headerInset.value), self.maxHeaderHeight.value)
      }.asDriver(onErrorJustReturn: maxHeaderHeight.value)
      .distinctUntilChanged()
      .drive(headerHeight)

    let maxHeaderHeightDispose = maxHeaderHeight
      .asDriver()
      .skip(1)
      .withLatestFrom(headerHeight.asDriver()) { ($0, $1) }
      .drive(onNext: { [weak collapsingItem = self.collapsingItem] maxHeight, height in
        if maxHeight == height {
          collapsingItem?.scrollView.contentOffset = CGPoint(x: 0, y: -maxHeight - self.headerInset.value)
        }
      })

    activeDispose = Disposables.create(headerHeightDispose, maxHeaderHeightDispose)
  }

  func disconnect() {
    guard connection != .disconnected else { return }
    connection = .disconnected

    activeDispose?.dispose()
    nonActiveDispose?.dispose()
    if let collapsingItem = collapsingItem {
      nonActiveDispose = headerHeight
        .asDriver()
        .distinctUntilChanged()
        .skip(1)
        .map {
          return CGPoint(x: 0, y: -$0 - self.headerInset.value)
        }.drive(collapsingItem.scrollView.rx.contentOffset)
    }
  }

  deinit {
    activeDispose?.dispose()
    nonActiveDispose?.dispose()
  }
}
