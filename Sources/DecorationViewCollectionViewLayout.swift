//
//  DecorationViewCollectionViewLayout.swift
//  UArena
//
//  Created by Sergei Mikhan on 8/1/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import RxSwift
import Astrolabe

class DecorationViewCollectionViewLayout<TitleViewModel: ViewModelable, MarkerCell: CollectionViewCell>: UICollectionViewFlowLayout {

  let progressVariable = Variable<Progress>(.init(pages: 0...0, progress: 0))
  var anchor: Anchor = .content
  var markerHeight: CGFloat = 15
  var titles: [TitleViewModel] = []

  fileprivate var disposeBag: DisposeBag?
  fileprivate var isScrolling = false

  fileprivate typealias TitleAttributes = TitleCollectionViewLayoutAttributes
  fileprivate typealias MarkerAttributes = MarkerDecorationAttributes<TitleViewModel, MarkerCell>

  private var cellFrames = [CGRect]()
  private var size = CGSize.zero

  private var setupFrames = true

  override func prepare() {
    super.prepare()

    guard let collectionView = collectionView else { return }
    guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return }

    register(MarkerCell.self, forDecorationViewOfKind: MarkerDecorationViewId)

    guard collectionView.numberOfSections == 1 else { return }

    let itemsCount = collectionView.numberOfItems(inSection: 0)
    guard itemsCount > 0 else { return }

    guard setupFrames else { return }
    setupFrames = false

    cellFrames = [CGRect]()
    cellFrames.reserveCapacity(itemsCount)

    size = .zero

    for itemIndex in stride(from: 0, to: collectionView.numberOfItems(inSection: 0), by: 1) {
      let indexPath = IndexPath(item: itemIndex, section: 0)
      var size = delegate.collectionView!(collectionView, layout: self, sizeForItemAt: indexPath)

      switch anchor {
      case .fillEqual:
        size.width = (collectionView.frame.width - (sectionInset.left + sectionInset.right)
          - CGFloat(itemsCount - 1) * minimumInteritemSpacing) / CGFloat(itemsCount)
      case let .equal(width):
        size.width = width
      default: break
      }

      var origin = CGPoint.zero

      if let lastFrame = cellFrames.last {
        origin.x = lastFrame.maxX + minimumLineSpacing
      } else {
        origin.x = sectionInset.left
      }

      // TODO: should we count here vertical sectionInsets?
      origin.y = (collectionView.frame.height - size.height) / 2

      cellFrames.append(CGRect(origin: origin, size: size))
    }

    if let last = cellFrames.last {
      size.width = last.maxX + sectionInset.right
    }

    size.height = collectionView.frame.height

    if disposeBag == nil {
      let disposeBag = DisposeBag()
      progressVariable.asDriver().distinctUntilChanged().drive(onNext: { [weak self] _ in
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = false
        context.invalidateFlowLayoutDelegateMetrics = false
        self?.invalidateLayout(with: context)
      }).disposed(by: disposeBag)
      collectionView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] _ in
        self?.isScrolling = false
      }).disposed(by: disposeBag)
      self.disposeBag = disposeBag
    }
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let attributes: [TitleAttributes] = cellFrames.enumerated().filter { $0.element.intersects(rect) }.map {
      let indexPath = IndexPath(item: $0.offset, section: 0)
      let attributes = TitleAttributes(forCellWith: indexPath)
      attributes.frame = $0.element
      return attributes
    }

    let progress = progressVariable.value

    var currentPages = [TitleAttributes]()
    var nextPages = [TitleAttributes]()

    let currentRange = progress.pages
    let nextRange = progress.pages.next

    attributes.forEach { itemAttributes in
      let index = itemAttributes.indexPath.item
      if currentRange ~= index && nextRange ~= index {
        itemAttributes.fade = 1.0
        currentPages.append(itemAttributes)
        nextPages.append(itemAttributes)
      } else if currentRange ~= index {
        itemAttributes.fade = 1.0 - progress.progress
        currentPages.append(itemAttributes)
      } else if nextRange ~= index {
        itemAttributes.fade = progress.progress
        nextPages.append(itemAttributes)
      } else {
        itemAttributes.fade = 0.0
      }
    }

    if currentPages.isEmpty {
      currentPages.append(contentsOf: currentRange.flatMap { index in
        guard cellFrames.indices.contains(index) else { return nil }
        let indexPath = IndexPath(item: index, section: 0)
        let attributes = TitleAttributes(forCellWith: indexPath)
        attributes.frame = cellFrames[index]
        return attributes
      })
    }

    let markerAttributes = decorationAttributes(for: currentPages, nextPages: nextPages.count > 0 ? nextPages : nil)
    let results: [UICollectionViewLayoutAttributes] = [markerAttributes].flatMap { $0 } + attributes

    return results
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard indexPath.section == 0, cellFrames.indices.contains(indexPath.item) else { return nil }
    let attributes = TitleAttributes(forCellWith: indexPath)
    attributes.frame = cellFrames[indexPath.item]
    return attributes
  }

  override var collectionViewContentSize: CGSize {
    return size
  }

  override class var layoutAttributesClass: AnyClass {
    return TitleAttributes.self
  }

  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)

    if let context = context as? UICollectionViewFlowLayoutInvalidationContext {
      setupFrames = context.invalidateFlowLayoutDelegateMetrics
    }
  }

}

extension DecorationViewCollectionViewLayout {

  fileprivate func decorationAttributes(for currentPages: [TitleAttributes],
                                        nextPages: [TitleAttributes]?) -> MarkerDecorationAttributes<TitleViewModel, MarkerCell>? {

    guard let collectionView = collectionView, currentPages.count > 0 else { return nil }

    let progress = progressVariable.value
    let decorationAttributes = MarkerAttributes(forDecorationViewOfKind: MarkerDecorationViewId, with: IndexPath(item: 0, section: 0))

    decorationAttributes.zIndex = -1
    decorationAttributes.apply(currentTitle: titles[safe: currentPages[0].indexPath.item],
                               nextTitle: titles[safe: currentPages[0].indexPath.item + 1],
                               progress: progress.progress)

    let currentFrame = currentPages.reduce(into: CGRect(), { result, attributes in
      if result == .zero {
        result = attributes.frame
      } else {
        result = result.union(attributes.frame)
      }
    })

    let nextFrame = nextPages?.reduce(into: CGRect(), { result, attributes in
      if result == .zero {
        result = attributes.frame
      } else {
        result = result.union(attributes.frame)
      }
    })

    decorationAttributes.frame = {
      let x: CGFloat
      let y = currentFrame.maxY - markerHeight
      let width: CGFloat
      let height = markerHeight

      if let nextFrame = nextFrame {
        width = currentFrame.width + progress.progress * (nextFrame.width - currentFrame.width)
        x = currentFrame.minX + progress.progress * (nextFrame.minX - currentFrame.minX)
      } else {
        width = currentFrame.width
        x = currentFrame.minX
      }
      return CGRect(x: x, y: y, width: width, height: height)
    }()

    switch anchor {
    case .content, .equal:
      adjustContentOffset(for: decorationAttributes,
                          collectionView: collectionView,
                          currentPage: currentPages, nextPage: nextPages)
    case .centered:
      adjustCenteredContentOffset(for: decorationAttributes,
                                  collectionView: collectionView)
    case .left(let offset):
      adjustLeftContentOffset(for: decorationAttributes,
                              collectionView: collectionView,
                              offset: offset)
    case .right(let offset):
      adjustRightContentOffset(for: decorationAttributes,
                              collectionView: collectionView,
                              offset: offset)
    default: break
    }

    return decorationAttributes
  }

  fileprivate func adjustContentOffset(for decorationAttributes: MarkerDecorationAttributes<TitleViewModel, MarkerCell>,
                                       collectionView: UICollectionView,
                                       currentPage: [TitleAttributes],
                                       nextPage: [TitleAttributes]?) {

    // NOTE: to avoid previous items attributes calculation
    // we can set additional visible gap to previous item at
    // half of current decoration view width
    let gap = decorationAttributes.frame.width / 2.0

    var point: CGPoint?
    if (decorationAttributes.frame.minX - minimumInteritemSpacing) < collectionView.contentOffset.x && !isScrolling {
      if currentPage[0].indexPath.item == 0 {
        point = .zero
      } else {
        point = CGPoint(x: currentPage[0].frame.minX - minimumInteritemSpacing - gap, y: 0)
      }
    }

    if (decorationAttributes.frame.maxX + minimumInteritemSpacing) > collectionView.contentOffset.x + collectionView.frame.width && !isScrolling,
      let nextPage = nextPage {
      if nextPage[0].indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 {
        point = CGPoint(x: collectionView.contentSize.width - collectionView.frame.width, y: 0)
      } else {
        point = CGPoint(x: nextPage[0].frame.maxX + minimumInteritemSpacing - collectionView.frame.width + gap, y: 0)
      }
    }

    if let targetPoint = point, targetPoint.x != collectionView.contentOffset.x {
      isScrolling = true
      collectionView.setContentOffset(targetPoint, animated: true)
    }
  }

  fileprivate func adjustCenteredContentOffset(for decorationAttributes: MarkerAttributes,
                                               collectionView: UICollectionView) {
    let target = CGPoint(x: decorationAttributes.frame.midX - (collectionView.frame.width) * 0.5, y: 0)
    collectionView.setContentOffset(target, animated: false)
  }

  fileprivate func adjustLeftContentOffset(for decorationAttributes: MarkerAttributes,
                                           collectionView: UICollectionView, offset: CGFloat) {
    let target = CGPoint(x: decorationAttributes.frame.minX - offset, y: 0)
    collectionView.setContentOffset(target, animated: false)
  }

  fileprivate func adjustRightContentOffset(for decorationAttributes: MarkerAttributes,
                                           collectionView: UICollectionView, offset: CGFloat) {
    let target = CGPoint(x: decorationAttributes.frame.maxX + offset - collectionView.frame.width, y: 0)
    collectionView.setContentOffset(target, animated: false)
  }
}
