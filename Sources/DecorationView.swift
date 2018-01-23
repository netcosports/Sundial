//
//  DecorationView.swift
//  PSGOneApp
//
//  Created by Sergei Mikhan on 5/31/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

public let DecorationViewId = "DecorationView"

class DecorationView<TitleCell: CollectionViewCell, MarkerCell: CollectionViewCell>: CollectionViewCell
      where TitleCell: Reusable, TitleCell.Data: ViewModelable {

  typealias Item                  = CollectionCell<TitleCell>

  typealias ViewModel             = TitleCell.Data
  typealias DecorationAttributes  = DecorationViewAttributes<ViewModel>
  typealias DecorationLayout      = DecorationViewCollectionViewLayout<ViewModel, MarkerCell>

  fileprivate let disposeBag = DisposeBag()
  fileprivate let decorationContainerView = CollectionView<CollectionViewSource>()
  fileprivate var layout: DecorationLayout?

  fileprivate weak var hostPagerSource: CollectionViewSource?
  fileprivate var currentLayoutAttributes: DecorationAttributes? {
    didSet {
      if let settings = currentLayoutAttributes?.settings, let layout = layout {
        layout.minimumLineSpacing = settings.itemMargin
        layout.minimumInteritemSpacing = settings.itemMargin
        layout.sectionInset = settings.inset
        layout.anchor = settings.anchor
        layout.markerHeight = settings.markerHeight
      }
    }
  }

  override func setup() {
    let layout = collectionViewLayout()
    self.layout = layout
    decorationContainerView.collectionViewLayout = layout
    if #available(iOS 10.0, tvOS 10.0, *) {
      decorationContainerView.isPrefetchingEnabled = false
    }
    contentView.addSubview(decorationContainerView)
    decorationContainerView.isScrollEnabled = false
    decorationContainerView.showsHorizontalScrollIndicator = false
    decorationContainerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: ["content": decorationContainerView]))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: ["content": decorationContainerView]))
    backgroundColor = UIColor.clear
  }

  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    if let decorationViewAttributes: DecorationViewAttributes<ViewModel> = convert(from: layoutAttributes) {
      guard let hostViewController = decorationViewAttributes.hostPagerSource?.hostViewController else {
        return
      }

      if decorationContainerView.source.hostViewController == nil {
        setupSource(for: decorationViewAttributes, in: hostViewController)
      }
      if !decorationViewAttributes.titles.elementsEqual(titles, by: {
        return $0.title == $1.title
      }) {
        titles = decorationViewAttributes.titles
      }
      backgroundColor = decorationViewAttributes.backgroundColor
      self.currentLayoutAttributes = decorationViewAttributes
    }
  }

  fileprivate func convert<T: UICollectionViewLayoutAttributes>(from layoutAttributes: UICollectionViewLayoutAttributes) -> T? {
    return layoutAttributes as? T
  }

  fileprivate var titles: [ViewModel] = [] {
    willSet(newTitles) {

      if newTitles.map({ $0.id }) == titles.map({ $0.id }) { return }

      let cells: [Cellable] = newTitles.map { title in
        let item = Item(data: title) { [weak self] in
          if let index = self?.titles.index(where: { $0.id == title.id }) {
            self?.currentLayoutAttributes?.selectionClosure?(index)
          }
        }
        item.id = title.title
        return item
      }

      if let layout = layout {
        layout.titles = newTitles

        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = true
        context.invalidateFlowLayoutDelegateMetrics = true
        layout.invalidateLayout(with: context)
      }

      decorationContainerView.source.sections = [Section(cells: cells)]
      decorationContainerView.reloadData()
    }
  }

  fileprivate func collectionViewLayout() -> DecorationLayout {
    let layout = DecorationLayout()
    layout.titles = titles
    layout.scrollDirection = .horizontal
    return layout
  }
}

extension DecorationView {

  fileprivate func setupSource(for layoutAttributes: DecorationAttributes,
                               in hostViewController: UIViewController) {
    self.hostPagerSource = layoutAttributes.hostPagerSource
    self.containerViewController = hostViewController
    decorationContainerView.source.hostViewController = hostViewController

    guard let layout = layout else { return }

    let contentSizeObservable: Observable<CGPoint> =
      decorationContainerView.rx.observe(CGSize.self, #keyPath(UICollectionView.contentSize))
        .distinctUntilChanged({
          $0?.width == $1?.width
        }).map({ [weak self] _ in
          return self?.hostPagerSource?.containerView?.contentOffset ?? CGPoint.zero
        })

    if let contentOffsetObservable = layoutAttributes.hostPagerSource?.containerView?.rx.contentOffset.asObservable() {
      let workaroundObservable = self.workaroundObservable()
      Observable.of(contentOffsetObservable, contentSizeObservable, workaroundObservable)
        .merge()
        .map { [weak self] offset -> Progress in
          if let containerView = self?.hostPagerSource?.containerView, let settings = layoutAttributes.settings {
            let width = containerView.frame.width / CGFloat(settings.pagesOnScreen)
            if width > 0.0 {
              let page = Int(offset.x / width)
              let progress = (offset.x - (width * CGFloat(page))) / width
              return .init(pages: page...(page + settings.pagesOnScreen - 1), progress: progress)
            }
          }
          return .init(pages: 0...0, progress: 0.0)
        }.bind(to: layout.progressVariable).disposed(by: disposeBag)
    }
  }

  fileprivate func workaroundObservable() -> Observable<CGPoint> {
    let contentOffsetObservable = decorationContainerView.rx.contentOffset.asObservable()
    let workaroundObservable = contentOffsetObservable.flatMap({ [weak self] _ -> Observable<CGPoint> in
      guard let containerView = self?.hostPagerSource?.containerView else { return .empty() }
      if !containerView.isDragging && !containerView.isTracking && !containerView.isDecelerating {
        return Observable<CGPoint>.just(containerView.contentOffset)
      }
      return .empty()
    })//.observeOn(MainScheduler.asyncInstance)
    return workaroundObservable
  }
}
