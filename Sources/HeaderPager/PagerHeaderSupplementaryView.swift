//
//  PagerHeaderSupplementaryView.swift
//  Sundial
//
//  Created by Sergei Mikhan on 08/23/19.
//  Copyright © 2019 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

public protocol PagerHeaderAttributes {
  var settings: Settings? { get }
  var invalidateTabFrames: Bool { get }
  var selectionClosure: ((Int) -> Void)? { get }
  var hostPagerSource: CollectionViewSource? { get }
}

public protocol PagerHeaderSupplementaryViewModel {
  associatedtype TitleCellViewModel
  var titles: [TitleCellViewModel] { get }
}

extension Array: PagerHeaderSupplementaryViewModel {

  public typealias TitleCellViewModel = Element

  public var titles: [Element] {
    return self
  }
}

public typealias PagerHeaderSupplementaryView<T: CollectionViewCell, M: CollectionViewCell> = GenericPagerHeaderSupplementaryView<[T.Data], T, M> where T: Reusable & Eventable, T.Data: Titleable, T.Data: Indicatorable, T.Event == T.Data

open class GenericPagerHeaderSupplementaryView<
  ViewModel: PagerHeaderSupplementaryViewModel & Hashable,
  T: CollectionViewCell,
  M: CollectionViewCell
>: CollectionViewCell, Reusable, Eventable
where T: Reusable & Eventable,
      T.Data: Titleable,
      T.Data: Indicatorable,
      T.Event == T.Data,
      ViewModel.TitleCellViewModel == T.Data {
  public var eventSubject = PublishSubject<Never>()
  public typealias Event = Never
  public var data: ViewModel?

  public typealias TitleCell                     = T
  public typealias MarkerCell                    = M
  public typealias Attributes                    = UICollectionViewLayoutAttributes & PagerHeaderAttributes
  public typealias HeaderPagerContentLayout      = PagerHeaderContentCollectionViewLayout<TitleCell.Data, MarkerCell>
  public typealias Item                          = CollectionCell<TitleCell>

  public let pagerHeaderContainerView = CollectionView<CollectionViewSource>()
  public var layout: HeaderPagerContentLayout?
  public weak var hostPagerSource: CollectionViewSource?

  private let titleSubject = PublishSubject<T.Data>()

  open class var layoutType: HeaderPagerContentLayout.Type { return HeaderPagerContentLayout.self }

  public let disposeBag = DisposeBag()
  fileprivate var currentLayoutAttributes: Attributes? {
    didSet {
      if let settings = currentLayoutAttributes?.settings, let layout = layout {
        layout.minimumLineSpacing = settings.itemMargin
        layout.minimumInteritemSpacing = settings.itemMargin
        layout.sectionInset = settings.inset
        layout.anchor = settings.anchor
        layout.markerHeight = settings.markerHeight
        pagerHeaderContainerView.isScrollEnabled = settings.pagerIndependentScrolling
        pagerHeaderContainerView.showsHorizontalScrollIndicator = settings.pagerIndependentScrolling

        if settings.pagerIndependentScrolling, let recognizer = hostPagerSource?.containerView?.panGestureRecognizer {
          recognizer.require(toFail: pagerHeaderContainerView.panGestureRecognizer)
        }
      }
    }
  }

  fileprivate var titles: [TitleCell.Data] = [] {
    willSet(newTitles) {

      #if DEBUG
      let ids = newTitles.map { $0.id }
      let set = Set<String>(ids)
      assert(ids.count == set.count, "provideds titles must have unique IDs")
      #endif

      let adjustedTitlesSet: [TitleCell.Data]
      if UIView.userInterfaceLayoutDirection(for: pagerHeaderContainerView.semanticContentAttribute) == .rightToLeft {
        adjustedTitlesSet = newTitles
      } else {
        adjustedTitlesSet = newTitles
      }

      if adjustedTitlesSet.map({ $0.id }) == titles.map({ $0.id }) { return }

      let cells: [Cellable] = adjustedTitlesSet.map { title in
        return Item(data: title, id: title.title, eventsEmmiter: titleSubject.asObserver(), clickEvent: title)
      }

      if let layout = layout {
        layout.titles = adjustedTitlesSet
        invalidateTabFrames(nil)
      }
      pagerHeaderContainerView.source.sections = [Section(cells: cells)]
      pagerHeaderContainerView.reloadData()
    }
  }

  override open func setup() {
    super.setup()

    titleSubject.subscribe(onNext: { [weak self] title in
      guard let self = self else { return }
      if let index = self.titles.firstIndex(where: { $0.active && $0.id == title.id }) {
        self.currentLayoutAttributes?.selectionClosure?(index)
      }
    }).disposed(by: disposeBag)

    let layout = collectionViewLayout()
    self.layout = layout
    pagerHeaderContainerView.collectionViewLayout = layout
    pagerHeaderContainerView.bounces = false
    if #available(iOS 10.0, tvOS 10.0, *) {
      pagerHeaderContainerView.isPrefetchingEnabled = false
    }
    pagerHeaderContainerView.showsHorizontalScrollIndicator = false
    contentView.addSubview(pagerHeaderContainerView)
    pagerHeaderContainerView.translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = UIColor.clear
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    layoutPagerHeaderContainerView()
  }

  open func layoutPagerHeaderContainerView() {
    pagerHeaderContainerView.frame = contentView.bounds
  }

  public typealias Data = ViewModel
  open func setup(with data: Data) {
    let titles = data.titles
    if !self.titles.elementsEqual(titles, by: {
      return $0.id == $1.id
    }) {
      self.titles = titles
    }
  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return containerSize
  }

  override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    if let pagerHeaderViewAttributes = layoutAttributes as? Attributes {
      let hostViewController = pagerHeaderViewAttributes.hostPagerSource?.hostViewController
      if pagerHeaderContainerView.source.hostViewController == nil {
        setupSource(for: pagerHeaderViewAttributes, in: hostViewController)
      }
      backgroundColor = pagerHeaderViewAttributes.settings?.backgroundColor
      self.currentLayoutAttributes = pagerHeaderViewAttributes

      if pagerHeaderViewAttributes.invalidateTabFrames {
        invalidateTabFrames(bounds.size.width)
      }
    }
  }
}

private extension GenericPagerHeaderSupplementaryView {

  func invalidateTabFrames(_ width: CGFloat?) {
    let context = HeaderPagerContentLayout.InvalidationContext()
    context.invalidateFlowLayoutAttributes = true
    context.invalidateFlowLayoutDelegateMetrics = true
    context.newCollectionViewWidth = width
    layout?.invalidateLayout(with: context)
  }

  func collectionViewLayout() -> HeaderPagerContentLayout {
    let layout = type(of: self).layoutType.init()
    layout.titles = titles
    layout.scrollDirection = .horizontal
    return layout
  }

  func setupSource(for layoutAttributes: Attributes, in hostViewController: UIViewController?) {
    self.hostPagerSource = layoutAttributes.hostPagerSource
    self.hostViewController = hostViewController
    pagerHeaderContainerView.source.hostViewController = hostViewController

    guard let layout = layout else { return }

    let contentSizeObservable: Observable<CGPoint> =
      pagerHeaderContainerView.rx.observe(CGSize.self, #keyPath(UICollectionView.contentSize), retainSelf: true)
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
        }.distinctUntilChanged().bind(to: layout.progress).disposed(by: disposeBag)
    }
  }

  func workaroundObservable() -> Observable<CGPoint> {
    let contentOffsetObservable = pagerHeaderContainerView.rx.contentOffset.asObservable()
    let workaroundObservable = contentOffsetObservable.flatMap({ [weak self] _ -> Observable<CGPoint> in
      guard let containerView = self?.hostPagerSource?.containerView else { return .empty() }
      if !containerView.isDragging && !containerView.isTracking && !containerView.isDecelerating {
        return Observable<CGPoint>.just(containerView.contentOffset)
      }
      return .empty()
    })
    return workaroundObservable
  }
}
