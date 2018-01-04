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

open class CollapsingCollectionViewLayout<
  Source: CollectionViewSource,
  TitleCell: CollectionViewCell,
  MarkerCell: CollectionViewCell>: CollectionViewLayout<Source, TitleCell, MarkerCell>
  where Source: Selectable, TitleCell: Reusable, TitleCell.Data: ViewModelable {

  public let minHeaderHeight = Variable<CGFloat>(0)
  public let maxHeaderHeight = Variable<CGFloat>(240)
  public let headerInset = Variable<CGFloat>(0)
  public let headerHeight = Variable<CGFloat>(120)
  public var expanded: Observable<Bool> { return expandedSubject.asObservable() }

  open class var headerZIndex: Int { return 1024 }

  fileprivate let expandedSubject = BehaviorSubject<Bool>(value: true)

  fileprivate var items: [CollapsingItem] = []
  fileprivate var handlers: [CollapsingHeaderHandler] = []
  fileprivate weak var connectedItem: CollapsingItem?
  fileprivate var updateMaxHeightDisposeBag: DisposeBag?

  public init(items: [CollapsingItem], hostPagerSource: Source, settings: Settings? = nil, pager: PagerClosure?) {
    super.init(hostPagerSource: hostPagerSource, settings: settings, pager: pager)
    self.items = items
    self.handlers = items.map { item in
      let handler = CollapsingHeaderHandler(with: item,
                                            min: minHeaderHeight,
                                            max: maxHeaderHeight,
                                            headerInset: headerInset,
                                            headerHeight: headerHeight)

      item.visible.asDriver().drive(onNext: { [weak handler, weak self] visible in
        if visible {
          handler?.connect()
          self?.connectedItem = item
        } else {
          handler?.disconnect()
        }
      }).disposed(by: self.disposeBag)
      return handler
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

    crashIfHeaderPresent(in: layoutAttributes)

    let headerIndexPath = IndexPath(item: 0, section: 0)
    let сollapsingHeaderViewAttributes = CollapsingHeaderViewAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                                                         with: headerIndexPath)
    сollapsingHeaderViewAttributes.zIndex = type(of: self).headerZIndex
    сollapsingHeaderViewAttributes.frame = CGRect(x: collectionView.contentOffset.x, y: 0.0,
                                                  width: collectionView.frame.width, height: headerHeight.value)

    layoutAttributes.append(сollapsingHeaderViewAttributes)

    return layoutAttributes
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

    if self.maxHeaderHeight.value > maxHeight {
      let updateMaxHeightDisposeBag = DisposeBag()
      connectedItem.scrollView.rx.didEndScrollingAnimation.asDriver().drive(onNext: {
        self.maxHeaderHeight.value = maxHeight
        self.updateMaxHeightDisposeBag = nil
      }).disposed(by: updateMaxHeightDisposeBag)
      self.updateMaxHeightDisposeBag = updateMaxHeightDisposeBag
    } else {
      self.maxHeaderHeight.value = maxHeight
    }
  }

  private func crashIfHeaderPresent(in items: [UICollectionViewLayoutAttributes]) {
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

  fileprivate weak var collapsingItem: CollapsingItem?

  private var connected = false
  private var activeDispose: Disposable?
  private var nonActiveDispose: Disposable?
  private let disposeBag = DisposeBag()

  init(with collapsingItem: CollapsingItem,
       min: Variable<CGFloat>,
       max: Variable<CGFloat>,
       headerInset: Variable<CGFloat>,
       headerHeight: Variable<CGFloat>) {

    self.collapsingItem = collapsingItem
    self.minHeaderHeight = min
    self.maxHeaderHeight = max
    self.headerHeight = headerHeight
    self.headerInset = headerInset

    let contentSizeDriver = collapsingItem.scrollView.rx
      .observe(CGSize.self, #keyPath(UICollectionView.contentSize))
      .asDriver(onErrorJustReturn: nil)
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
      let contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
      collapsingItem.scrollView.contentInset = contentInset
      collapsingItem.scrollView.scrollIndicatorInsets = contentInset
    }).disposed(by: disposeBag)
  }

  func connect() {
    guard !connected else { return }
    connected = true

    collapsingItem?.scrollView.contentOffset = CGPoint(x: 0, y: -headerHeight.value - headerInset.value) // -40
    activeDispose?.dispose()
    nonActiveDispose?.dispose()

    let headerHeightDispose = collapsingItem?.scrollView.rx.contentOffset.asObservable().skip(1).distinctUntilChanged()
      .map { [unowned self] in
        return min(max(self.minHeaderHeight.value, -$0.y - self.headerInset.value), self.maxHeaderHeight.value)
      }.asDriver(onErrorJustReturn: maxHeaderHeight.value).distinctUntilChanged().drive(headerHeight)

    let maxHeaderHeightDispose = maxHeaderHeight.asDriver().skip(1)
      .withLatestFrom(headerHeight.asDriver()) { ($0, $1) }
      .drive(onNext: { [weak collapsingItem = self.collapsingItem] maxHeight, height in
        if maxHeight == height {
          collapsingItem?.scrollView.contentOffset = CGPoint(x: 0, y: -maxHeight - self.headerInset.value) // -40
        }
      })
    if let headerHeightDispose = headerHeightDispose {
      activeDispose = Disposables.create(headerHeightDispose, maxHeaderHeightDispose)
    }
  }

  func disconnect() {
    guard connected else { return }
    connected = false

    activeDispose?.dispose()
    nonActiveDispose?.dispose()
    if let collapsingItem = collapsingItem {
      nonActiveDispose = headerHeight.asDriver().distinctUntilChanged()
        .map { CGPoint(x: 0, y: -$0) }.drive(collapsingItem.scrollView.rx.contentOffset)
    }
  }

  deinit {
    activeDispose?.dispose()
    nonActiveDispose?.dispose()
  }
}
