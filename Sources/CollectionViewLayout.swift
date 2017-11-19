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

open class CollectionViewLayout<T: CollectionViewSource, TitleCell: CollectionViewCell, MarkerCell: CollectionViewCell>: UICollectionViewFlowLayout
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

  public convenience init(hostPagerSource: T, settings: Settings? = nil, pager: PagerClosure?) {
    self.init()

    sectionInset = .zero
    minimumLineSpacing = 0.0
    minimumInteritemSpacing = 0.0
    scrollDirection = .horizontal

    self.hostPagerSource = hostPagerSource
    self.pager = pager
    if let settings = settings {
      self.settings = settings
    }
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let oldAttributes = super.layoutAttributesForElements(in: rect)

    if var attributes = oldAttributes?.flatMap({ $0.copy() as?
      UICollectionViewLayoutAttributes }), let collectionView = collectionView {
      if attributes.count == 0 { return oldAttributes }
      guard let titles = pager?() else { return oldAttributes }

      guard titles.count > 0 else { return oldAttributes }

      attributes.forEach {
        let original = $0.frame
        let bottom = settings.bottomStripSpacing
        let height = settings.stripHeight
        $0.frame = CGRect(x: original.origin.x, y: height + bottom,
                          width: original.width, height: original.height - height - bottom)
      }

      let decorationIndexPath = IndexPath(item: 0, section: 0)
      let decorationAttributes = DecorationViewAttributes<ViewModel>(forDecorationViewOfKind: DecorationViewId, with: decorationIndexPath)

      decorationAttributes.settings = settings
      decorationAttributes.titles = titles
      decorationAttributes.hostPagerSource = hostPagerSource
      decorationAttributes.backgroundColor = pageStripBackgroundColor
      decorationAttributes.selectionClosure = { [weak self] in
        if let selectedItem = self?.hostPagerSource?.selectedItem {
          selectedItem.onNext($0)
        }
      }
      decorationAttributes.frame = CGRect(x: collectionView.contentOffset.x,
                                          y: 0.0,
                                          width: collectionView.frame.width,
                                          height: settings.stripHeight)
      attributes.append(contentsOf: [decorationAttributes])
      return attributes
    }

    return oldAttributes
  }

  open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }
}
