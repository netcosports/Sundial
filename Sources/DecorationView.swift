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

open class GenericDecorationView<T: CollectionViewCell, M: CollectionViewCell, A: UICollectionViewLayoutAttributes & Attributable>:
  CollectionViewCell, DecorationViewPageable where T: Reusable, T.Data == A.TitleViewModel, T.Data: Indicatorable {

  public typealias TitleCell = T
  public typealias MarkerCell = M
  public typealias Attributes = A

  typealias Item                         = CollectionCell<TitleCell>
  public typealias ViewModel             = TitleCell.Data
  public typealias DecorationLayout      = DecorationViewCollectionViewLayout<ViewModel, MarkerCell>

  fileprivate let disposeBag = DisposeBag()
  open let decorationContainerView = CollectionView<CollectionViewSource>()

  public private(set) var layout: DecorationLayout?

  open class var layoutType: DecorationLayout.Type { return DecorationLayout.self }

  fileprivate weak var hostPagerSource: CollectionViewSource?
  fileprivate var currentLayoutAttributes: Attributes? {
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

  override open func setup() {
    super.setup()

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

    let views = ["content": decorationContainerView]
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil,
                                                              views: views))
    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[content]|", metrics: nil,
                                                              views: views))
    backgroundColor = UIColor.clear
  }

  override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    if let decorationViewAttributes: Attributes = convert(from: layoutAttributes) {
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
      backgroundColor = decorationViewAttributes.settings?.backgroundColor
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
    let layout = type(of: self).layoutType.init()
    layout.titles = titles
    layout.scrollDirection = .horizontal
    return layout
  }

  fileprivate func setupSource(for layoutAttributes: Attributes,
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
