//
//  PlainCollectionViewLayout.swift
//  Sundial
//
//  Created by Dmitry Duleba on 8/24/18.
//

import Foundation
import Astrolabe
import RxSwift
import RxCocoa

open class PlainCollectionViewLayout: UICollectionViewFlowLayout, PreparedLayout {

  public typealias Source = CollectionViewSource & Selectable

  open weak var hostPagerSource: Source?
  open var settings: Settings  { didSet { applySettings() } }

  open override var collectionViewContentSize: CGSize {
    if settings.shouldKeepFocusOnBoundsChange {
      return contentSize
    }
    return super.collectionViewContentSize
  }

  public var ready: (() -> Void)?
  public var readyObservable: Observable<Void> { return readySubject }

  let disposeBag = DisposeBag()
  var currentIndex: Int? {
    guard let source = hostPagerSource, let collectionView = collectionView,
      collectionView.bounds.size.width > 0.0 else { return nil }

    let index = Int(collectionView.contentOffset.x / collectionView.bounds.size.width)
    let pagesCount = source.sections.first?.cells.count ?? 0
    let result = max(0, min(index, pagesCount - 1))
    return result
  }

  private var layoutData = [IndexPath: UICollectionViewLayoutAttributes]()
  private var contentSize = CGSize.zero
  private var selectedIndexPath = IndexPath(item: 0, section: 0)
  private var settingsReuseBag: DisposeBag?

  private let readySubject = PublishSubject<Void>()
  private var jumpSourceLayoutAttribute: UICollectionViewLayoutAttributes?
  private var jumpTargetLayoutAttribute: UICollectionViewLayoutAttributes?

  private var shouldScrollToSelectedIndex = false

  // MARK: - Init

  public init(hostPagerSource: Source, settings: Settings? = nil) {
    self.settings = settings ?? Settings()
    super.init()

    sectionInset = .zero
    minimumLineSpacing = 0.0
    minimumInteritemSpacing = 0.0
    scrollDirection = .horizontal

    self.hostPagerSource = hostPagerSource
    applySettings()
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Overrides

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    if settings.shouldKeepFocusOnBoundsChange && newBounds.size != collectionView?.bounds.size {
      shouldScrollToSelectedIndex = true
    }
    return true
  }

  open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    // TODO: Should we take into account .invalidateFlowLayoutAttributes and .invalidateFlowLayoutDelegateMetrics ?
    layoutData.removeAll()
    contentSize = .zero
  }

  open override func prepare() {
    if settings.shouldKeepFocusOnBoundsChange {
      calculateLayout()
    } else {
      super.prepare()
    }

    ready?()
    readySubject.onNext(())

    if settings.shouldKeepFocusOnBoundsChange && shouldScrollToSelectedIndex {
      shouldScrollToSelectedIndex = false
      if let offset = layoutAttributesForItem(at: selectedIndexPath)?.frame.origin {
        collectionView?.setContentOffset(offset, animated: false)
      }
    }
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let sourceAttributes: [UICollectionViewLayoutAttributes]
    if settings.shouldKeepFocusOnBoundsChange {
      sourceAttributes = layoutData
        .compactMap { (_, value) -> UICollectionViewLayoutAttributes? in
          if rect.intersects(value.frame) {
            return value
          }
          return nil
      }
    } else {
      sourceAttributes = super.layoutAttributesForElements(in: rect) ?? []
    }
    var attributes = sourceAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

    addJumpAttributes(to: &attributes)
    return attributes
  }

  open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    if settings.shouldKeepFocusOnBoundsChange {
      return layoutData[indexPath]
    } else {
      return super.layoutAttributesForItem(at: indexPath)
    }
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    guard settings.shouldKeepFocusOnBoundsChange else {
      return proposedContentOffset
    }

    guard let collectionView = collectionView,
      let currentAttributes = layoutAttributesForItem(at: selectedIndexPath) else {
        return proposedContentOffset
    }

    let width = collectionView.bounds.size.width
    let result = CGPoint(x: currentAttributes.frame.midX - width * 0.5, y: proposedContentOffset.y)
    return result
  }

  open override var collectionView: UICollectionView? {
    get {
      let result = super.collectionView
      if settings.shouldKeepFocusOnBoundsChange {
        result?.decelerationRate = UIScrollView.DecelerationRate.fast
      }
      return result
    }
  }

  // MARK: - Private

  private func applySettings() {
    let disposeBag = DisposeBag()

    if settings.shouldKeepFocusOnBoundsChange {
      hostPagerSource?.selectedItem.asObservable()
        .subscribe(onNext: { [weak self] index in
          guard let `self` = self, let selectedIndexPath = self.indexPath(for: index) else { return }

          self.selectedIndexPath = selectedIndexPath
        })
        .disposed(by: disposeBag)
    }

    switch settings.alignment {
    case .topOffset(let value):
      value.asDriver().drive(onNext: { [weak self] _ in
        self?.invalidateLayout()
      }).disposed(by: disposeBag)
    default: break
    }
    settingsReuseBag = disposeBag
  }

  // TODO: should we handle more general case? (When we have 2+ sections)
  private func indexPath(for item: Int) -> IndexPath? {
    let result = IndexPath(item: item, section: 0)
    guard layoutAttributesForItem(at: result) != nil else { return nil }

    return result
  }

  // MARK: Jumping

  public func select(item: Int, animated: Bool = false) {
    let isLayoutReady = (layoutData.count > 0 || !settings.shouldKeepFocusOnBoundsChange)
      ? Observable.just(Void())
      : readySubject.take(1)
    isLayoutReady
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [weak self] in
        guard let `self` = self, let selectedIndexPath = self.indexPath(for: item) else { return }

        self.shouldScrollToSelectedIndex = false
        self.selectedIndexPath = selectedIndexPath
        if animated {
          self.select(item: item, jumpingPolicy: self.settings.jumpingPolicy)
          return
        }

        guard let collectionView = self.collectionView,
          let itemFrame = self.layoutAttributesForItem(at: self.selectedIndexPath)?.frame else { return }

        collectionView.contentOffset = CGPoint(x: itemFrame.origin.x, y: itemFrame.origin.y)
      })
      .disposed(by: disposeBag)
  }

  internal func select(item: Int, jumpingPolicy: JumpingPolicy) {
    let threshold: Int
    switch jumpingPolicy {
    case .disabled: threshold = .max
    case .skip(let pages): threshold = max(pages, 2)
    }
    
    selectedIndexPath = indexPath(for: item) ?? selectedIndexPath
    guard let currentIndex = currentIndex, abs(currentIndex - item) >= threshold else {
      hostPagerSource?.selectedItem.onNext(item)
      return
    }

    jump(from: currentIndex, to: item)
  }

  private func jump(from source: Int, to target: Int) {
    if jumpTargetLayoutAttribute != nil || jumpSourceLayoutAttribute != nil {
      return
    }

    let sourceIndex = IndexPath(item: source, section: 0)
    let targetIndex = IndexPath(item: target, section: 0)
    guard let sourceLayoutAttributes = layoutAttributesForItem(at: sourceIndex)?.copy() as? UICollectionViewLayoutAttributes,
      let targetLayoutAttributes = layoutAttributesForItem(at: targetIndex)?.copy() as? UICollectionViewLayoutAttributes else {
        return
    }

    jumpTargetLayoutAttribute = targetLayoutAttributes
    jumpSourceLayoutAttribute = sourceLayoutAttributes

    invalidateLayout()
    hostPagerSource?.containerView?.isUserInteractionEnabled = false
    hostPagerSource?.containerView?.layoutIfNeeded()
    hostPagerSource?.selectedItem.onNext(target)
  }

  internal func addJumpAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > 0 else { return }
    guard let containerView = hostPagerSource?.containerView else { return }
    guard let source = jumpSourceLayoutAttribute?.copy() as? UICollectionViewLayoutAttributes,
      let target = jumpTargetLayoutAttribute?.copy() as? UICollectionViewLayoutAttributes else {
        return
    }

    let sourceStartFrame = source.frame
    let targetEndFrame = target.frame
    let width = containerView.frame.size.width
    let offet = containerView.contentOffset.x
    let midPoint = offet + width * 0.5
    let distanceLeft = abs(targetEndFrame.midX - midPoint)
    let totalDistance = abs(targetEndFrame.midX - sourceStartFrame.midX)
    guard totalDistance > 0.0, distanceLeft > 0.0, target.indexPath.item != source.indexPath.item else {
      finalizeJumpTransition()
      return
    }

    let pagesDistance = CGFloat(abs(target.indexPath.item - source.indexPath.item))
    let progressPerPage = 1.0 / pagesDistance
    let progress = 1.0 - (distanceLeft / totalDistance)

    let sourceEndProgress = 1.0 - progressPerPage
    let sourceEndFrame = sourceStartFrame.linearInterpolation(with: targetEndFrame, value: sourceEndProgress)
    let sourceFrame = sourceStartFrame.linearInterpolation(with: sourceEndFrame, value: progress)
    source.frame = sourceFrame

    let targetStartProgress = progressPerPage
    let targetStartFrame = sourceStartFrame.linearInterpolation(with: targetEndFrame, value: targetStartProgress)
    let targetFrame = targetStartFrame.linearInterpolation(with: targetEndFrame, value: progress)
    target.frame = targetFrame

    attributes = attributes.filter { $0.representedElementCategory != .cell }
    attributes.append(contentsOf: [source, target])
  }

  private func finalizeJumpTransition() {
    jumpTargetLayoutAttribute = nil
    jumpSourceLayoutAttribute = nil
    hostPagerSource?.containerView?.isUserInteractionEnabled = true
  }

  // MARK: Keeping Focus

  private func calculateLayout() {
    guard let collectionView = collectionView,
      let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return }

    var x: CGFloat = 0.0
    var y: CGFloat = 0.0
    let sections = collectionView.numberOfSections
    (0..<sections).forEach { section in
      let items = collectionView.numberOfItems(inSection: section)
      (0..<items)
        .map { item in IndexPath(item: item, section: section) }
        .forEach { indexPath in
          if let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            layoutData[indexPath] = attributes
            switch scrollDirection {
            case .horizontal: x += size.width
            case .vertical: y += size.height
            }
            contentSize.width = max(contentSize.width, attributes.frame.maxX)
            contentSize.height = max(contentSize.height, attributes.frame.maxY)
          }
      }
    }
  }

}
