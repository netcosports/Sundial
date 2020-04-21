//
//  CalendarDayCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 4/20/20.
//

import UIKit
import Astrolabe

public typealias CalendarDayOffset = (timestamps: Int, relative: CGFloat)
public protocol CalendarDayIntervalContainer {
  var start: CalendarDayOffset { get }
  var end: CalendarDayOffset { get }
}

public enum SupplementaryViewKind {
  public static let calendayDayTimestamp = "SupplementaryViewKind.calendayDayTimestamp"
}

open class CalendarDayCollectionViewLayout: EmptyViewCollectionViewLayout {

  public struct Settings {

    public let insets: UIEdgeInsets
    public let horizontalMargin: CGFloat
    public let timestampHeight: CGFloat

    public init(insets: UIEdgeInsets = .zero,
                horizontalMargin: CGFloat = 0.0,
                timestampHeight: CGFloat = 0.0) {
      self.insets = insets
      self.horizontalMargin = horizontalMargin
      self.timestampHeight = timestampHeight
    }
  }

  open var settings = Settings() {
    didSet {
      invalidateLayout()
    }
  }

  typealias Attributes = UICollectionViewLayoutAttributes

  private var itemsAttributes: [IndexPath: Attributes] = [:]
  private var supplementaryAttributes: [IndexPath: Attributes] = [:]
  private var contentSize = CGSize.zero
  private var hostPagerSource: CollectionViewSource?

  public init(hostPagerSource: CollectionViewSource, settings: Settings? = nil) {
    super.init()
    self.hostPagerSource = hostPagerSource
    if let settings = settings {
      self.settings = settings
    }
    scrollDirection = .horizontal
    minimumLineSpacing = 0.0
    minimumInteritemSpacing = 0.0
    sectionInset = .zero
  }

  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open func prepare() {
    super.prepare()
    guard let collectionView = collectionView,
      !collectionView.bounds.isEmpty,
      itemsAttributes.isEmpty || supplementaryAttributes.isEmpty else { return }
    reload()
  }

  override open var collectionViewContentSize: CGSize {
    return contentSize
  }

  override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    itemsAttributes.removeAll()
    supplementaryAttributes.removeAll()
    contentSize = .zero
  }

  override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let items = itemsAttributes
      .filter { $0.value.frame.intersects(rect) }
      .map { $0.value }
    let supplementaries = supplementaryAttributes
      .filter { $0.value.frame.intersects(rect) }
      .map { $0.value }

    return items + supplementaries
  }

  override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return itemsAttributes[indexPath]
  }
}

private extension CalendarDayCollectionViewLayout {

  private func reload() {
    guard let collectionView = collectionView, collectionView.numberOfSections > 0 else { return }

    let width = collectionView.frame.width
    let totalHours = 24

    let x: CGFloat = 0.0
    var y: CGFloat = settings.insets.top
    let supplementaryWidth = width - settings.insets.left - settings.insets.right
    let numberOfCells = collectionView.numberOfItems(inSection: 0)
    (0..<totalHours).forEach { supplementary in
      let indexPath = IndexPath(item: supplementary, section: 0)
      let supplementaryAttribute = Attributes(forSupplementaryViewOfKind: SupplementaryViewKind.calendayDayTimestamp,
                                              with: indexPath)
      supplementaryAttribute.frame = CGRect(x: x, y: y,
                                            width: supplementaryWidth,
                                            height: settings.timestampHeight)
      supplementaryAttribute.zIndex = -supplementary
      supplementaryAttributes[indexPath] = supplementaryAttribute
      y += settings.timestampHeight + settings.horizontalMargin
    }
    contentSize = CGSize(width: width, height: y + settings.insets.bottom)
    (0..<numberOfCells).forEach { cellIndex in
      let cell = hostPagerSource?.sections[safe: 0]?.cells[safe: cellIndex] as? CalendarDayIntervalContainer
      guard let start = cell?.start, let end = cell?.end else { return }
      let indexPath = IndexPath(item: cellIndex, section: 0)
      let cellAttribute = Attributes(forCellWith: indexPath)
      let y = CGFloat(start.timestamps) * (settings.timestampHeight + settings.horizontalMargin) +
              start.relative * settings.timestampHeight
      let relativeHeight = (CGFloat(end.timestamps) + end.relative - (CGFloat(start.timestamps) + start.relative))
      let height = settings.timestampHeight * relativeHeight
      cellAttribute.frame = CGRect(x: x, y: y,
                                   width: supplementaryWidth,
                                   height: height)
      cellAttribute.zIndex = cellIndex
      itemsAttributes[indexPath] = cellAttribute
    }
  }
}
