//
//  EmptyViewCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 7/4/19.
//

import UIKit
import Astrolabe
import RxSwift

public protocol Decorationable {
  static var kind: String { get }
  static var zIndex: Int { get }
}

open class EmptyViewCollectionViewLayout: UICollectionViewFlowLayout, PreparedLayout {

  public struct EmptyViewSettings {
    public let height: CGFloat

    public init(height: CGFloat = 120.0) {
      self.height = height
    }
  }

  public typealias LoaderDecoration = UICollectionViewCell & Decorationable

  public var ready: (() -> Void)?
  public var readyObservable: Observable<Void> { return readySubject }
  public var emptyViewSettings = EmptyViewSettings()

  let disposeBag = DisposeBag()
  let readySubject = PublishSubject<Void>()

  private var emptyViewDecoration: LoaderDecoration.Type?
  private var loaderDecoration: LoaderDecoration.Type?
  private var showEmptyView: BehaviorSubject<Bool>?
  private var showLoaderView: BehaviorSubject<Bool>?
  private var reloadSubject: PublishSubject<Void>?
  private var emptyViewDisposeBag: DisposeBag?
  private var loaderDisposeBag: DisposeBag?

  open override func prepare() {
    super.prepare()
    ready?()
    readySubject.onNext(())
  }

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    // NOTE: important to perform this, because when sectionHeadersPinToVisibleBounds is true
    // `layoutAttributesForElements` is not called even when `shouldInvalidateLayout` is true
    if sectionHeadersPinToVisibleBounds, let loaderDecoration = loaderDecoration {
      let context = UICollectionViewFlowLayoutInvalidationContext()
      context.invalidateDecorationElements(ofKind: loaderDecoration.kind, at: [IndexPath(index: 1)])
      self.invalidateLayout(with: context)
    }
    return true
  }

  open override var collectionViewContentSize: CGSize {
    guard let collectionView = collectionView else { return super.collectionViewContentSize }
    let size = super.collectionViewContentSize
    if size.height < emptyViewSettings.height && (needToShowEmptyView || needToShowLoaderView) {
      return CGSize(width: collectionView.frame.width, height: emptyViewSettings.height)
    }
    return size
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var originalAttributes = super.layoutAttributesForElements(in: rect)
    guard collectionView != nil else { return originalAttributes }
    if let emptyViewDecorationAttributes = emptyViewDecorationAttributes(), emptyViewDecorationAttributes.frame.intersects(rect) {
      originalAttributes?.append(emptyViewDecorationAttributes)
    }
    if let loaderViewDecorationAttributes = loaderViewDecorationAttributes(), loaderViewDecorationAttributes.frame.intersects(rect) {
      originalAttributes?.append(loaderViewDecorationAttributes)
    }
    return originalAttributes
  }

  open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    if elementKind == loaderDecoration?.kind {
      return loaderViewDecorationAttributes()
    } else if elementKind == emptyViewDecoration?.kind {
      return emptyViewDecorationAttributes()
    } else {
      return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
    }
  }
}

extension EmptyViewCollectionViewLayout {

  public func register<T: LoaderDecoration>(loaderDecoration: T.Type, showLoaderView: BehaviorSubject<Bool>) {
    register(loaderDecoration, forDecorationViewOfKind: loaderDecoration.kind)
    self.showLoaderView = showLoaderView
    self.loaderDecoration = loaderDecoration

    let loaderDisposeBag = DisposeBag()
    showLoaderView.asObservable()
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.invalidateLayout()
      }).disposed(by: loaderDisposeBag)
    self.loaderDisposeBag = loaderDisposeBag
  }

  func loaderViewDecorationAttributes() -> UICollectionViewLayoutAttributes? {
    guard let collectionView = collectionView else { return nil }
    guard let loaderDecoration = loaderDecoration else { return nil }

    let decorationIndexPath = IndexPath(index: 1)
    let decorationAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: loaderDecoration.kind,
                                                                with: decorationIndexPath)
    decorationAttributes.zIndex = loaderDecoration.zIndex
    decorationAttributes.isHidden = !needToShowLoaderView
    let width = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right
    let height = collectionView.frame.height - collectionView.contentInset.top
    let size = CGSize(width: width, height: height)
    var offset = collectionView.contentOffset
    if offset.x < 0.0 && scrollDirection == .horizontal {
      offset.x = 0.0
    }
    if offset.y < 0.0 && scrollDirection == .vertical {
      offset.y = 0.0
    }
    decorationAttributes.frame = CGRect(origin: offset, size: size)
    return decorationAttributes
  }

  var needToShowLoaderView: Bool {
    guard let showLoaderView = showLoaderView else { return false }
    guard (try? showLoaderView.value()) == true else { return false }
    return true
  }
}

extension EmptyViewCollectionViewLayout {

  public func register<T: LoaderDecoration>(emptyViewDecoration: T.Type,
                                            showEmptyView: BehaviorSubject<Bool>,
                                            reloadSubject: PublishSubject<Void>) {
    register(emptyViewDecoration, forDecorationViewOfKind: emptyViewDecoration.kind)
    self.emptyViewDecoration = emptyViewDecoration
    self.showEmptyView = showEmptyView
    self.reloadSubject = reloadSubject

    let emptyViewDisposeBag = DisposeBag()
    showEmptyView.asObservable()
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.invalidateLayout()
      }).disposed(by: disposeBag)
    self.emptyViewDisposeBag = emptyViewDisposeBag
  }

  func emptyViewDecorationAttributes() -> EmptyViewAttributes? {
    guard let emptyViewDecoration = emptyViewDecoration else { return nil }
    guard let collectionView = collectionView else { return nil }
    let decorationIndexPath = IndexPath(index: 0)
    let decorationAttributes = EmptyViewAttributes(forDecorationViewOfKind: emptyViewDecoration.kind,
                                                   with: decorationIndexPath)
    decorationAttributes.zIndex = emptyViewDecoration.zIndex
    decorationAttributes.reloadSubject = reloadSubject
    decorationAttributes.isHidden = !needToShowEmptyView
    let width = collectionView.frame.width - collectionView.contentInset.left - collectionView.contentInset.right
    let height = collectionView.frame.height - collectionView.contentInset.top
    let size = CGSize(width: width, height: height)
    decorationAttributes.frame = CGRect(origin: .zero, size: size)
    return decorationAttributes
  }

  var needToShowEmptyView: Bool {
    guard let showEmptyView = showEmptyView else { return false }
    guard (try? showEmptyView.value()) == true else { return false }
    guard let collectionView = collectionView else { return true }
    guard collectionView.numberOfSections != 0 else { return true }
    guard collectionView.numberOfItems(inSection: 0) != 0 else { return true }
    return false
  }
}
