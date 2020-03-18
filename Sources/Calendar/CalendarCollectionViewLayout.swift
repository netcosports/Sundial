//
//  CalendarCollectionViewLayout.swift
//  Sundial
//
//  Created by Sergei Mikhan on 3/18/20.
//

import UIKit

open class CalendarCollectionViewLayout: EmptyViewCollectionViewLayout {

  public struct Settings {

    public enum Alignment {
      case fill
      case center
    }

    public let alignment: Alignment
    public let insets: UIEdgeInsets
    public let horizontalMargin: CGFloat
    public let verticalMargin: CGFloat

    public init(alignment: Alignment,
                insets: UIEdgeInsets = .zero,
                horizontalMargin: CGFloat = 0.0,
                verticalMargin: CGFloat = 0.0) {
      self.alignment = alignment
      self.insets = insets
      self.horizontalMargin = horizontalMargin
      self.verticalMargin = verticalMargin
    }
  }

  open var settings = Settings(alignment: .fill) {
    didSet {
      invalidateLayout()
    }
  }

  public struct MonthLayout {

    let startDayIndex: Int

    public init(startDayIndex: Int) {
      self.startDayIndex = startDayIndex
    }
  }

  public var monthLayoutClosure: ((Int) -> MonthLayout)? = nil

  typealias Attributes = UICollectionViewLayoutAttributes

  private var itemsAttributes: [IndexPath: Attributes] = [:]
  private var contentSize = CGSize.zero

  public override init() {
    super.init()
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
    guard let collectionView = collectionView, !collectionView.bounds.isEmpty, itemsAttributes.isEmpty else { return }
    reload()
  }

  override open var collectionViewContentSize: CGSize {
    return contentSize
  }

  override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
    itemsAttributes.removeAll()
    contentSize = .zero
  }

  override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return itemsAttributes
      .filter { $0.value.frame.intersects(rect) }
      .map { $0.value }
  }

  override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return itemsAttributes[indexPath]
  }
}

private extension CalendarCollectionViewLayout {

  private func reload() {
    guard let collectionView = collectionView else { return }

    let daysAWeek = 7
    let width = collectionView.frame.width
    let height = collectionView.frame.height

    let sections = collectionView.numberOfSections
    (0..<sections).forEach { section in
      let totalDays = collectionView.numberOfItems(inSection: section)
      let month = monthLayoutClosure?(section) ?? MonthLayout(startDayIndex: 0)
      let dayCellWidth = (width
        - settings.insets.left
        - settings.insets.right
        - CGFloat(daysAWeek - 1) * settings.horizontalMargin) / CGFloat(daysAWeek)

      let dayCellHeight = (height
        - settings.insets.top
        - settings.insets.bottom
        - CGFloat(daysAWeek - 1) * settings.verticalMargin) / CGFloat(daysAWeek)

      let dayWidthWithMargin = dayCellWidth + settings.horizontalMargin
      let dayHeightWithMargin = dayCellHeight + settings.verticalMargin

      let originX = CGFloat(section) * width + settings.insets.left
      var x = originX + CGFloat(month.startDayIndex) * dayWidthWithMargin
      var y = settings.insets.top

      (0..<totalDays).forEach { day in
        let indexPath = IndexPath(item: day, section: section)
        let cellAttribute = Attributes(forCellWith: indexPath)
        cellAttribute.frame = CGRect(x: x, y: y, width: dayCellWidth, height: dayCellHeight)
        itemsAttributes[indexPath] = cellAttribute

        x += dayWidthWithMargin
        if (day + 1 + month.startDayIndex) % daysAWeek == 0 {
          x = originX
          y += dayHeightWithMargin
        }
      }
    }
    contentSize = CGSize(width: CGFloat(sections) * width, height: height)
  }
}
