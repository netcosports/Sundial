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

  let progressVariable = Variable<Progress>((0...0, 0))
  var anchor: Anchor = .content
  var markerHeight: CGFloat = 15
  var titles: [TitleViewModel] = []

  fileprivate var disposeBag: DisposeBag?
  fileprivate var isScrolling = false

  fileprivate typealias TitleAttributes = TitleCollectionViewLayoutAttributes
  fileprivate typealias MarkerAttributes = MarkerDecorationAttributes<TitleViewModel, MarkerCell>

  override func prepare() {
    super.prepare()

    register(MarkerCell.self, forDecorationViewOfKind: MarkerDecorationViewId)

    if disposeBag == nil {
      guard let collectionView = collectionView else { return }
      let disposeBag = DisposeBag()
      progressVariable.asDriver().drive(onNext: { [weak self] _ in
        self?.invalidateLayout()
      }).disposed(by: disposeBag)
      collectionView.rx.didEndScrollingAnimation.asDriver().drive(onNext: { [weak self] _ in
        self?.isScrolling = false
      }).disposed(by: disposeBag)
      self.disposeBag = disposeBag
    }
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let oldAttributes = super.layoutAttributesForElements(in: rect)

    guard let attributes = oldAttributes?.flatMap({ $0.copy() as? TitleAttributes }) else {
      return nil
    }

    let progress = progressVariable.value

    var currentPages = [TitleAttributes]()
    var nextPages = [TitleAttributes]()

    switch anchor {
    case .fillEqual, .equal:
      guard let collectionView = collectionView else { return nil }
      guard collectionView.numberOfSections > 0 else { return nil }

      let count = collectionView.numberOfItems(inSection: 0)
      let width: CGFloat

      switch anchor {
      case .fillEqual:
        width = (collectionView.frame.width - (sectionInset.left + sectionInset.right) - CGFloat(count - 1) * minimumInteritemSpacing) / CGFloat(count)
      case .equal(let size):
        width = size
      default: width = 0
      }

      var x = sectionInset.left
      attributes.forEach { itemAttributes in
        var frame = itemAttributes.frame
        frame.origin.x = x
        frame.size.width = width
        itemAttributes.frame = frame

        x = x + width + minimumInteritemSpacing
      }
    default: break
    }

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

    let markerAttributes = decorationAttributes(for: currentPages, nextPages: nextPages.count > 0 ? nextPages : nil)
    let results: [UICollectionViewLayoutAttributes] = [markerAttributes].flatMap { $0 } + attributes

    return results
  }

  override var collectionViewContentSize: CGSize {
    let contentSize = super.collectionViewContentSize
    guard let collectionView = collectionView else { return contentSize }

    switch anchor {
    case .fillEqual:
      return CGSize(width: collectionView.frame.width, height: contentSize.height)
    case .equal(let size):
      guard collectionView.numberOfSections > 0 else { return contentSize }

      let count = CGFloat(collectionView.numberOfItems(inSection: 0))
      let width = sectionInset.left + sectionInset.right + (count - 1.0) * minimumInteritemSpacing + count * size
      return CGSize(width: width, height: contentSize.height)
    default:
      return contentSize
    }
  }

  override class var layoutAttributesClass: AnyClass {
    return TitleAttributes.self
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
