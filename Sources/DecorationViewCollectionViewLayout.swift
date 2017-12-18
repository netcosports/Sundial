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

  let progressVariable = Variable<Progress>((0, 0))
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

    var currentPage: TitleAttributes?
    var nextPage: TitleAttributes?

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

    attributes.forEach { itemAttributes in
      switch itemAttributes.indexPath.item {
      case progress.page:
        itemAttributes.fade = 1.0 - progress.progress
        currentPage = itemAttributes
      case progress.page + 1:
        itemAttributes.fade = progress.progress
        nextPage = itemAttributes
      default: itemAttributes.fade = 0.0
      }
    }

    let markerAttributes = decorationAttributes(for: currentPage, nextPage: nextPage)
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

  fileprivate func decorationAttributes(for currentPage: TitleAttributes?,
                                        nextPage: TitleAttributes?) -> MarkerDecorationAttributes<TitleViewModel, MarkerCell>? {

    guard let currentPage = currentPage, let collectionView = collectionView else {
      return nil
    }

    let progress = progressVariable.value
    let decorationAttributes = MarkerAttributes(forDecorationViewOfKind: MarkerDecorationViewId, with: IndexPath(item: 0, section: 0))

    decorationAttributes.apply(currentTitle: titles[safe: currentPage.indexPath.item],
                               nextTitle: titles[safe: currentPage.indexPath.item + 1],
                               progress: progress.progress)

    decorationAttributes.frame = {
      let x: CGFloat
      let y = currentPage.frame.maxY - markerHeight
      let width: CGFloat
      let height = markerHeight

      if let nextPage = nextPage {
        width = currentPage.frame.width + progress.progress * (nextPage.frame.width - currentPage.frame.width)
        x = currentPage.frame.minX + progress.progress * (nextPage.frame.minX - currentPage.frame.minX)
      } else {
        width = currentPage.frame.width
        x = currentPage.frame.minX
      }
      return CGRect(x: x, y: y, width: width, height: height)
    }()



    switch anchor {
    case .content, .equal:
      adjustContentOffset(for: decorationAttributes,
                          collectionView: collectionView,
                          currentPage: currentPage, nextPage: nextPage)
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
                                       currentPage: TitleAttributes,
                                       nextPage: TitleAttributes?) {

    if decorationAttributes.frame.minX < collectionView.contentOffset.x && !isScrolling {
      isScrolling = true
      if currentPage.indexPath.item == 0 {
        collectionView.setContentOffset(.zero, animated: true)
      } else {
        let point = CGPoint(x: currentPage.frame.minX - minimumInteritemSpacing, y: 0)
        collectionView.setContentOffset(point, animated: true)
      }
    }

    if decorationAttributes.frame.maxX > collectionView.contentOffset.x + collectionView.frame.width && !isScrolling,
      let nextPage = nextPage {
      isScrolling = true
      if nextPage.indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 {
        let target = CGPoint(x: collectionView.contentSize.width - collectionView.frame.width, y: 0)
        collectionView.setContentOffset(target, animated: true)
      } else {
        let point = CGPoint(x: nextPage.frame.maxX + minimumInteritemSpacing - collectionView.frame.width, y: 0)
        collectionView.setContentOffset(point, animated: true)
      }
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
