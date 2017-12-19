//
//  CollectionViewLayout.swift
//  PSGOneApp
//
//  Created by Eugen Filipkov on 4/17/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe
import RxSwift
import RxCocoa

open class CollectionViewLayout<T: CollectionViewSource,
  TitleCell: CollectionViewCell,
  MarkerCell: CollectionViewCell>: UICollectionViewFlowLayout
  where T: Selectable, TitleCell: Reusable, TitleCell.Data: ViewModelable {

  public typealias ViewModel = TitleCell.Data

  open override func prepare() {
    super.prepare()
    register(DecorationView<TitleCell, MarkerCell>.self, forDecorationViewOfKind: DecorationViewId)
  }

  public typealias PagerClosure = ()->[ViewModel]

  open weak var hostPagerSource: T?
  open var pager: PagerClosure?
  open var pageStripBackgroundColor = UIColor.clear
  open var settings: Settings = Settings()

  let disposeBag = DisposeBag()

  public init(hostPagerSource: T, settings: Settings? = nil, pager: PagerClosure?) {
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

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let oldAttributes = super.layoutAttributesForElements(in: rect)

    if var attributes = oldAttributes?.flatMap({ $0.copy() as? UICollectionViewLayoutAttributes }) {
      if attributes.count == 0 { return oldAttributes }
      guard let titles = pager?() else { return oldAttributes }

      guard titles.count > 0 else { return oldAttributes }

      attributes.forEach {
        $0.frame = adjustItem(frame: $0.frame)
      }

      let decorationIndexPath = IndexPath(item: 0, section: 0)
      let decorationAttributes = DecorationViewAttributes<ViewModel>(forDecorationViewOfKind: DecorationViewId, with: decorationIndexPath)

      decorationAttributes.zIndex = 1024
      decorationAttributes.settings = settings
      decorationAttributes.titles = titles
      decorationAttributes.hostPagerSource = hostPagerSource
      decorationAttributes.backgroundColor = pageStripBackgroundColor
      let validPagesRange = 0...(titles.count - settings.pagesOnScreen)
      decorationAttributes.selectionClosure = { [weak self] in
        if let selectedItem = self?.hostPagerSource?.selectedItem {
          if validPagesRange ~= $0 {
            selectedItem.onNext($0)
          } else {
            selectedItem.onNext(min(max(validPagesRange.lowerBound, $0), validPagesRange.upperBound))
          }
        }
      }
      decorationAttributes.frame = decorationFrame
      attributes.append(decorationAttributes)
      return attributes
    }

    return oldAttributes
  }

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

  open func adjustItem(frame: CGRect) -> CGRect {
    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }
}
