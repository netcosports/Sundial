//
//  DecorationViewCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 8/1/17.
//  Copyright © 2017 NetcoSports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Astrolabe

open class DecorationViewCollectionViewLayout<TitleViewModel: ViewModelable, MarkerCell: CollectionViewCell>: UICollectionViewFlowLayout {

  open class InvalidationContext: UICollectionViewFlowLayoutInvalidationContext {
    public var newCollectionViewWidth: CGFloat?
  }

  public let progress = BehaviorRelay<Progress>(value: .init(pages: 0 ... 0, progress: 0))
  public internal(set) var anchor: Anchor = .content(.left)
  public internal(set) var markerHeight: CGFloat = 15
  public internal(set) var titles: [TitleViewModel] = []

  fileprivate var disposeBag: DisposeBag?

  fileprivate typealias TitleAttributes = TitleCollectionViewLayoutAttributes
  fileprivate typealias MarkerAttributes = MarkerDecorationAttributes<TitleViewModel, MarkerCell>

  private var cellFrames = [CGRect]()
  private var size = CGSize.zero

  private var setupFrames = true
  private var newCollectionViewWidth: CGFloat?

  required override public init() {
    super.init()
  }

  required public init?(coder aDecoder: NSCoder) { fatalError() }

  override open func prepare() {
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

    let collectionViewWidth = newCollectionViewWidth ?? collectionView.frame.width
    let equalWidth = (collectionViewWidth - (sectionInset.left + sectionInset.right)
      - CGFloat(itemsCount - 1) * minimumInteritemSpacing) / CGFloat(itemsCount)

    for itemIndex in 0 ..< collectionView.numberOfItems(inSection: 0) {
      let indexPath = IndexPath(item: itemIndex, section: 0)
      var size = delegate.collectionView!(collectionView, layout: self, sizeForItemAt: indexPath)

      switch anchor {
      case .fillEqual:
        size.width = equalWidth
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

    if case let .content(distribution) = anchor, size.width < collectionViewWidth {
      switch distribution {
      case .left:
        size.width = collectionViewWidth
      case .right:
        let offset = collectionViewWidth - size.width

        cellFrames = cellFrames.map { frame -> CGRect in
          var frame = frame
          frame.origin.x += offset
          return frame
        }

        size.width = collectionViewWidth
      case .center:
        let offset = (collectionViewWidth - size.width) / 2

        cellFrames = cellFrames.map { frame -> CGRect in
          var frame = frame
          frame.origin.x += offset
          return frame
        }

        size.width = collectionViewWidth
      case .proportional, .inverseProportional:

        func inverseIfNeeded(_ value: CGFloat) -> CGFloat {
          guard distribution == .inverseProportional else { return value }
          return 1 / value
        }

        let diff = collectionViewWidth - size.width
        let proportion = diff / cellFrames.map { inverseIfNeeded($0.width) }.reduce(0, +)

        var lastFrame: CGRect?

        cellFrames = cellFrames.map { frame -> CGRect in
          var frame = frame

          frame.size.width += proportion * inverseIfNeeded(frame.width)

          if let lastFrame = lastFrame {
            frame.origin.x = lastFrame.maxX + minimumLineSpacing
          } else {
            frame.origin.x = sectionInset.left
          }

          lastFrame = frame
          return frame
        }

        if let last = cellFrames.last {
          size.width = last.maxX + sectionInset.right
        }
      case .equalSpacing:
        var availableSpace = collectionViewWidth - size.width + sectionInset.left + sectionInset.right
          + (CGFloat(cellFrames.count) - 1) * minimumLineSpacing
        var count = CGFloat(cellFrames.count) + 1
        var spacing = availableSpace / count

        let leftInset, rightInset: CGFloat

        if sectionInset.left > spacing {
          leftInset = sectionInset.left

          availableSpace -= leftInset
          count -= 1
          spacing = availableSpace / count
        } else {
          leftInset = spacing
        }

        if sectionInset.right > spacing {
          rightInset = sectionInset.right

          availableSpace -= rightInset
          count -= 1
          spacing = availableSpace / count
        } else {
          rightInset = spacing
        }

        guard minimumLineSpacing <= spacing else { break }

        var lastFrame: CGRect?

        cellFrames = cellFrames.map { frame -> CGRect in
          var frame = frame

          if let lastFrame = lastFrame {
            frame.origin.x = lastFrame.maxX + spacing
          } else {
            frame.origin.x = leftInset
          }

          lastFrame = frame
          return frame
        }

        if let last = cellFrames.last {
          size.width = last.maxX + rightInset
        }
      }
    }

    size.height = collectionView.frame.height

    if disposeBag == nil {
      let disposeBag = DisposeBag()
      progress.asDriver().drive(onNext: { [weak self] _ in
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = false
        context.invalidateFlowLayoutDelegateMetrics = false
        self?.invalidateLayout(with: context)
      }).disposed(by: disposeBag)
      self.disposeBag = disposeBag
    }
  }

  override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let titleAttributes: [TitleAttributes] = cellFrames.enumerated().filter { $0.element.intersects(rect) }.map {
      let indexPath = IndexPath(item: $0.offset, section: 0)
      let attributes = TitleAttributes(forCellWith: indexPath)
      attributes.frame = $0.element
      return attributes
    }

    let progressValue = progress.value

    var currentPages = [TitleAttributes]()
    var nextPages = [TitleAttributes]()

    let currentRange = progressValue.pages
    let nextRange = progressValue.pages.next

    titleAttributes.forEach { itemAttributes in
      let index = itemAttributes.indexPath.item
      if currentRange ~= index && nextRange ~= index {
        itemAttributes.fade = 1.0
        currentPages.append(itemAttributes)
        nextPages.append(itemAttributes)
      } else if currentRange ~= index {
        itemAttributes.fade = 1.0 - progressValue.progress
        currentPages.append(itemAttributes)
      } else if nextRange ~= index {
        itemAttributes.fade = progressValue.progress
        nextPages.append(itemAttributes)
      } else {
        itemAttributes.fade = 0.0
      }
    }

    if currentPages.isEmpty {
      currentPages.append(contentsOf: currentRange.compactMap { index in
        guard cellFrames.indices.contains(index) else { return nil }
        let indexPath = IndexPath(item: index, section: 0)
        let attributes = TitleAttributes(forCellWith: indexPath)
        attributes.frame = cellFrames[index]
        return attributes
      })
    }

    if nextPages.isEmpty {
      nextPages.append(contentsOf: nextRange.compactMap { index in
        guard cellFrames.indices.contains(index) else { return nil }
        let indexPath = IndexPath(item: index, section: 0)
        let attributes = TitleAttributes(forCellWith: indexPath)
        attributes.frame = cellFrames[index]
        return attributes
      })
    }

    var attributes = titleAttributes as [UICollectionViewLayoutAttributes]

    if let markerAttributes = decorationAttributes(for: currentPages, nextPages: !nextPages.isEmpty ? nextPages : nil) {
      attributes.append(markerAttributes)
    }

    return attributes
  }

  override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard indexPath.section == 0, cellFrames.indices.contains(indexPath.item) else { return nil }
    let attributes = TitleAttributes(forCellWith: indexPath)
    attributes.frame = cellFrames[indexPath.item]
    return attributes
  }

  override open var collectionViewContentSize: CGSize {
    return size
  }

  override open class var layoutAttributesClass: AnyClass {
    return TitleAttributes.self
  }

  override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)

    if let context = context as? InvalidationContext {
      setupFrames = context.invalidateFlowLayoutDelegateMetrics
      newCollectionViewWidth = context.newCollectionViewWidth
    }
  }

}

extension DecorationViewCollectionViewLayout {

  fileprivate func decorationAttributes(for currentPages: [TitleAttributes],
                                        nextPages: [TitleAttributes]?) -> MarkerDecorationAttributes<TitleViewModel, MarkerCell>? {

    guard let collectionView = collectionView, currentPages.count > 0 else { return nil }

    let progressValue = progress.value
    let decorationAttributes = MarkerAttributes(forDecorationViewOfKind: MarkerDecorationViewId,
                                                with: IndexPath(item: 0, section: 0))

    decorationAttributes.zIndex = -1
    decorationAttributes.apply(currentTitle: titles[safe: currentPages[0].indexPath.item],
                               nextTitle: titles[safe: currentPages[0].indexPath.item + 1],
                               progress: progressValue.progress)

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
        width = currentFrame.width + progressValue.progress * (nextFrame.width - currentFrame.width)
        x = currentFrame.minX + progressValue.progress * (nextFrame.minX - currentFrame.minX)
      } else {
        width = currentFrame.width
        x = currentFrame.minX
      }
      return CGRect(x: x, y: y, width: width, height: height)
    }()

    switch anchor {
    case .content, .equal:
      adjustContentOffset(for: decorationAttributes, collectionView: collectionView)
    case .centered:
      adjustCenteredContentOffset(for: decorationAttributes, collectionView: collectionView)
    case .left(let offset):
      adjustLeftContentOffset(for: decorationAttributes, collectionView: collectionView, offset: offset)
    case .right(let offset):
      adjustRightContentOffset(for: decorationAttributes, collectionView: collectionView, offset: offset)
    default: break
    }

    return decorationAttributes
  }

  fileprivate func adjustContentOffset(for decorationAttributes: MarkerAttributes, collectionView: UICollectionView) {
    var target = max(0, decorationAttributes.frame.midX - (collectionView.frame.width) * 0.5)
    target = min(target, collectionView.contentSize.width - collectionView.frame.width)
    guard target >= 0 else { return }
    collectionView.setContentOffset(CGPoint(x: target, y: 0), animated: false)
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
