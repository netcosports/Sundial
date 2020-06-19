//
//  CalendarDayViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 4/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//


import UIKit
import Astrolabe
import Sundial

extension CollectionCell: CalendarDayIntervalContainer where Data: CalendarDayIntervalContainer {

  public var start: CalendarDayOffset {
    return data.start
  }

  public var end: CalendarDayOffset {
    return data.end
  }
}

public class NowIndicatorCell: CollectionViewCell, Reusable {

  public struct ViewModel: CalendarDayIntervalContainer {
    public var start: CalendarDayOffset
    public var end: CalendarDayOffset
  }

  public typealias Data = ViewModel

  public override func setup() {
    super.setup()
    backgroundColor = .red
  }

  public func setup(with data: ViewModel) {

  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 10.0)
  }
}

public class EventCell: CollectionViewCell, Reusable {

  public struct ViewModel: CalendarDayIntervalContainer {
    public var start: CalendarDayOffset
    public var end: CalendarDayOffset
    var title: String
  }

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    title.backgroundColor = .black
    return title
  }()

  open override func setup() {
    super.setup()
    contentView.addSubview(title)
    title.backgroundColor = UIColor.red.withAlphaComponent(0.33)
    title.snp.remakeConstraints {
      $0.top.bottom.leading.trailing.equalToSuperview()
    }
  }

  public typealias Data = ViewModel

  open func setup(with data: Data) {
    title.text = data.title
  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 100.0)
  }
}

public class TimestampCell: CollectionViewCell, Reusable {

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .left
    title.backgroundColor = .black
    return title
  }()

  let separator: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()

  open override func setup() {
    super.setup()
    contentView.addSubview(title)
    contentView.addSubview(separator)

    title.snp.remakeConstraints {
      $0.top.bottom.leading.trailing.equalToSuperview()
    }

    separator.snp.remakeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.height.equalTo(1.0)
    }
  }

  public typealias Data = String

  open func setup(with data: Data) {
    title.text = data
  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return containerSize
  }
}

extension DateInterval: DateIntervalContainer {

  public var interval: DateInterval {
    return self
  }
}

class CalendarDayViewController: UIViewController {

  let collectionView = CollectionView<CollectionViewSource>()

  override func viewDidLoad() {
    super.viewDidLoad()

    let timestampFormatter = DateFormatter()
    timestampFormatter.dateFormat = "HH:mm"

    let minute = 60.0
    let hour = 60.0 * minute
    let date = Calendar.current.startOfDay(for: Date())
    let events: [DateInterval] = [
      DateInterval(start: date.addingTimeInterval(hour * 5.0), duration: 50.0 * minute),
      DateInterval(start: date.addingTimeInterval(hour * 8.4), duration: 2.0 * hour),
      DateInterval(start: date.addingTimeInterval(hour * 12.0), duration: 40.0 * minute),
      DateInterval(start: date.addingTimeInterval(hour * 16.0), duration: 55.0 * minute),
      DateInterval(start: date.addingTimeInterval(hour * 20.0), duration: 1.0 * hour),
      DateInterval(start: date.addingTimeInterval(hour * 20.0), duration: 20.0 * minute),
    ]

    let input = Sundial.CallendarDayFactoryInput<DateInterval>(startDate: Date(), events: events)
    let sections = Sundial.callendarDayFactory(input: input, supplementaryClosure: { type in
      switch type {
      case .nowIndicator(let date):
        let data = NowIndicatorCell.ViewModel(start: date, end: date)
        return CollectionCell<NowIndicatorCell>(data: data,
                                                type: .custom(kind: SupplementaryViewKind.currentTimeIndicator))
      case .timestamp(let date):
        return CollectionCell<TimestampCell>(data: timestampFormatter.string(from: date),
                                             type: .custom(kind: SupplementaryViewKind.calendayDayTimestamp))
      }
    }, cellClosure: { interval, start, end -> (Cellable & CalendarDayIntervalContainer) in
      let data = EventCell.ViewModel(start: start, end: end,
                                     title: timestampFormatter.string(from: interval.start))
      return CollectionCell<EventCell>(data: data)
    })

    let layout = CalendarDayCollectionViewLayout(
      hostPagerSource: collectionView.source,
      settings: .init(timestampHeight: 120.0, startHour: 8, finishHour: 23)
    )
    collectionView.collectionViewLayout = layout

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    collectionView.source.sections = sections
    collectionView.reloadData()
  }
}
