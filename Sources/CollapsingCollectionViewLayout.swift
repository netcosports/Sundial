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

  public let minHeaderHeight = BehaviorRelay<CGFloat>(value: 0)
  public let maxHeaderHeight = BehaviorRelay<CGFloat>(value: 240)
  public let headerInset = BehaviorRelay<CGFloat>(value: 0)
  public let headerHeight = BehaviorRelay<CGFloat>(value: 120)
  public var expanded: Observable<Bool> { return expandedSubject.asObservable() }
  public let followOffsetChanges = BehaviorRelay<Bool>(value: false)

  open class var headerZIndex: Int { return 1024 }

  fileprivate let expandedSubject = BehaviorSubject<Bool>(value: true)
  fileprivate var handlers: [CollapsingHeaderHandler] = []
  fileprivate weak var connectedItem: CollapsingItem?
  fileprivate var updateMaxHeightDisposeBag: DisposeBag?

  // MARK: - Init

  public init(items: [CollapsingItem], hostPagerSource: Source, settings: Settings? = nil, pager: PagerClosure?) {
    super.init(hostPagerSource: hostPagerSource, settings: settings, pager: pager)
    self.handlers = items.compactMap { [weak self] item in
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

    headerInset.accept(self.settings.stripHeight)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public required init(hostPagerSource: Source, settings: Settings?, pager: PagerClosure?) {
    fatalError("init(hostPagerSource:settings:pager:) has not been implemented")
  }

  // MARK: - Override

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
    let сollapsingHeaderViewAttributes = CollapsingHeaderViewAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: headerIndexPath)
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

  open func append(collapsingItems: [CollapsingItem]) {
    let handlers: [CollapsingHeaderHandler] = collapsingItems.compactMap { item in
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
      if attributes.representedElementCategory == .supplementaryView && attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
        if attributes.size != .zero {
          fatalError("collapsing header size(for:, containerSize:) -> CGSize should return .zero")
        }
      }
    }
  }
}

