//
//  CollectionViewLayout.swift
//  Sundial
//
//  Created by Eugen Filipkov on 4/17/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

public protocol PreparedLayout {
  var readyObservable: Observable<Void> { get }
}

open class GenericCollectionViewLayout<DecorationView: CollectionViewCell & DecorationViewPageable>: UICollectionViewFlowLayout, PreparedLayout {

  public typealias ViewModel = DecorationView.TitleCell.Data
  public typealias PagerClosure = ()->[ViewModel]
  public typealias Source = CollectionViewSource & Selectable

  open weak var hostPagerSource: Source?
  open var pager: PagerClosure?
  open var settings: Settings = Settings()
  open var decorationFrame: CGRect {
    guard let collectionView = collectionView else { return .zero }

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

  open override var collectionViewContentSize: CGSize { return contentSize }

  public var ready: (() -> Void)?
  public var readyObservable: Observable<Void> { return readySubject }

  //  public var invalidateTabFrames = false
  //  public var newCollectionViewWidth: CGFloat?
  //  public var target: CGPoint?

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
  private(set) var selectedIndexPath = IndexPath(item: 0, section: 0)

  private let readySubject = PublishSubject<Void>()
  private var jumpSourceLayoutAttribute: UICollectionViewLayoutAttributes?
  private var jumpTargetLayoutAttribute: UICollectionViewLayoutAttributes?

  // MARK: - Init

  public init(hostPagerSource: Source, settings: Settings? = nil, pager: PagerClosure?) {
    super.init()

    sectionInset = .zero
    minimumLineSpacing = 0.0
    minimumInteritemSpacing = 0.0
    scrollDirection = .horizontal

    self.hostPagerSource = hostPagerSource
    self.pager = pager
    if let settings = settings {
      self.settings = settings
    }

    hostPagerSource.selectedItem.asObservable()
      .observeOn(MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] index in
        guard let `self` = self else { return }

        var orderedIndexes = [Int: IndexPath]()
        self.layoutData.keys.sorted().enumerated()
          .forEach {
            orderedIndexes[$0.offset] = $0.element
        }

        if let selectedIndexPath = orderedIndexes[index] {
          self.selectedIndexPath = selectedIndexPath
        }
      })
    .disposed(by: disposeBag)

    rx.observe(UICollectionView.self, "collectionView")
      .subscribe(onNext: { [weak self] collectionView in
        collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
      })
    .disposed(by: disposeBag)

    // TODO: should we do it every time settings are set via setter?
    switch self.settings.alignment {
    case .topOffset(let variable):
      variable.asDriver().drive(onNext: { [weak self] _ in
        self?.invalidateLayout()
      }).disposed(by: disposeBag)
    default: break
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Overrides

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }

  open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    // TODO: Should we take into account UICollectionViewFlowLayoutInvalidationContext.invalidateFlowLayoutAttributes and UICollectionViewFlowLayoutInvalidationContext.invalidateFlowLayoutDelegateMetrics ???
    layoutData.removeAll()
    contentSize = .zero
  }

  open override func prepare() {
    calculateLayout()
    register(DecorationView.self, forDecorationViewOfKind: DecorationViewId)

    ready?()
    readySubject.onNext(())
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let oldAttributes = layoutData
      .compactMap { (_, value) -> UICollectionViewLayoutAttributes? in
        if rect.intersects(value.frame) {
          return value
        }
        return nil
    }
    var attributes = oldAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

    addDecorationAttributes(to: &attributes)
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

  open override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard elementKind == DecorationViewId, indexPath == IndexPath(item: 0, section: 0) else { return nil }
    return decorationAttributes(with: pager?())
  }

  //  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
  //    return proposedContentOffset // target ?? proposedContentOffset
  //  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    guard let collectionView = collectionView,
      let currentAttributes = layoutAttributesForItem(at: selectedIndexPath) else {
        return proposedContentOffset
    }

    let width = collectionView.bounds.size.width
    let result = CGPoint(x: currentAttributes.frame.midX - width * 0.5, y: proposedContentOffset.y)
    return result
  }

  open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                         withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let currentAttributes = layoutAttributesForItem(at: selectedIndexPath),
      let attributes = self.attributes(for: proposedContentOffset) else {
        return proposedContentOffset
    }

    let distance = attributes.indexPath.item - currentAttributes.indexPath.item
    let maxDistance = 1 // isLandscape ? 1 : 1
    let targetAttributes: UICollectionViewLayoutAttributes
    if abs(distance) <= maxDistance {
      targetAttributes = attributes
    } else {
      let targetIndex = currentAttributes.indexPath.item + distance.signum()
      targetAttributes = layoutData[IndexPath(item: targetIndex, section: 0)] ?? currentAttributes
    }

    self.selectedIndexPath = targetAttributes.indexPath
    var targetOffset = alignmentOffset(for: targetAttributes)
    checkDirection(for: &targetOffset, velocity: velocity)

    return targetOffset
  }

  // MARK: - Open

  open func adjustItem(frame: CGRect) -> CGRect {
    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  open func decorationAttributes(with titles: [ViewModel]?) -> DecorationView.Attributes? {
    guard let titles = titles, titles.count > 0 else {
      return nil
    }

    let settings = self.settings
    let validPagesRange = 0...(titles.count - settings.pagesOnScreen)
    let decorationIndexPath = IndexPath(item: 0, section: 0)
    let decorationAttributes = DecorationView.Attributes(forDecorationViewOfKind: DecorationViewId, with: decorationIndexPath)
    decorationAttributes.zIndex = 1024
    decorationAttributes.settings = settings
    decorationAttributes.titles = titles
    decorationAttributes.hostPagerSource = hostPagerSource
    decorationAttributes.selectionClosure = { [weak self] in
      guard let `self` = self else { return }

      let item = $0.clamp(to: validPagesRange)
      self.select(item: item, jumpingPolicy: settings.jumpingPolicy)
    }
    decorationAttributes.frame = decorationFrame

    //    if invalidateTabFrames {
    //      decorationAttributes.invalidateTabFrames = invalidateTabFrames
    //      decorationAttributes.newCollectionViewWidth = newCollectionViewWidth
    //    }

    return decorationAttributes
  }

  // MARK: - Internal

  func addDecorationAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > 0 else { return }
    guard let decorationAttributes = self.decorationAttributes(with: pager?()) else {
      return
    }

    attributes.forEach {
      $0.frame = adjustItem(frame: $0.frame)
    }
    attributes.append(decorationAttributes)
  }

  // MARK: - Private

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

  // MARK: Jumping

  private func select(item: Int, jumpingPolicy: JumpingPolicy) {
    let threshold: Int
    switch jumpingPolicy {
    case .disabled: threshold = .max
    case .skip(let pages): threshold = max(pages, 2)
    }
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

  private func addJumpAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
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

  // MARK: Paging

  // TODO: What should we do if settings.pages > 1 ?
  private func attributes(for contentOffset: CGPoint) -> UICollectionViewLayoutAttributes? {
    guard let collectionView = collectionView else {
      return nil
    }

    let width = collectionView.bounds.size.width
    let visualCenter = contentOffset.x + width * 0.5
    return layoutData.values
      .min(by: {
        let lhs = abs(visualCenter - $0.frame.midX)
        let rhs = abs(visualCenter - $1.frame.midX)
        return lhs < rhs
      })
  }

  // TODO: What should we do if settings.pages > 1 ?
  private func alignmentOffset(for attributes: UICollectionViewLayoutAttributes) -> CGPoint {
    guard let width = collectionView?.bounds.size.width, width > 0.0 else {
      return .zero
    }

    let result = CGPoint(x: attributes.frame.midX - width * 0.5, y: 0.0)
    return result
  }

  private func checkDirection(for targetOffset: inout CGPoint, velocity: CGPoint) {
    guard let collectionView = collectionView else { return }

    var indexedOrders = [IndexPath: Int]()
    var orderedIndexes = [Int: IndexPath]()
    layoutData.keys.sorted().enumerated()
      .forEach {
        indexedOrders[$0.element] = $0.offset
        orderedIndexes[$0.offset] = $0.element
    }

    guard let selectedIndex = indexedOrders[selectedIndexPath] else { return }

    let delta = targetOffset.x - collectionView.contentOffset.x
    let sameDirections = (delta < 0.0) == (velocity.x < 0.0) || velocity.x == 0.0
    if !sameDirections {
      let lowerBound = 0
      let upperBound = layoutData.count - 1
      var targetIndex = selectedIndex
      if velocity.x < 0.0 && selectedIndex > lowerBound {
        targetIndex = selectedIndex - 1
      } else if velocity.x > 0.0 && selectedIndex < upperBound {
        targetIndex = selectedIndex + 1
      }
      if targetIndex != selectedIndex,
        let targetIndexPath = orderedIndexes[targetIndex],
        let targetAttributes = layoutData[targetIndexPath] {
          selectedIndexPath = targetIndexPath
          targetOffset = alignmentOffset(for: targetAttributes)
      }
    }
  }
}

// MARK: - Rx

public extension Reactive where Base: PreparedLayout {

  var ready: ControlEvent<Void> {
    return ControlEvent(events: base.readyObservable)
  }

}
