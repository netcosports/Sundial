//
//  CalendarViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 3/18/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial

import RxSwift
import RxCocoa

public class DayCell: CollectionViewCell, Reusable, Eventable {
  public let eventSubject = PublishSubject<Event>()
  public typealias Event = String
  public var data: Data?

  let day: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    title.backgroundColor = .black
    return title
  }()

  let month: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    title.backgroundColor = .black
    title.numberOfLines = 0
    return title
  }()

  open override func setup() {
    super.setup()
    contentView.addSubview(day)
    contentView.addSubview(month)

    day.snp.remakeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(contentView.snp.centerY)
    }
    month.snp.remakeConstraints {
      $0.bottom.leading.trailing.equalToSuperview()
      $0.top.equalTo(contentView.snp.centerY)
    }
  }

  public struct ViewModel: Hashable {
    public init(day: String, month: String) {
      self.day = day
      self.month = month
    }

    let day: String
    let month: String
  }

  public typealias Data = ViewModel

  open func setup(with data: Data) {
    day.text = data.day
    month.text = data.month
  }

  public static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return containerSize
  }
}

class CalendarViewController: UIViewController {

  let collectionView = CollectionView<CollectionViewSource>()

  override func viewDidLoad() {
    super.viewDidLoad()

    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "dd"

    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM"

    let results = Sundial.callendarFactory(
      input: .init(monthsForwardCount: 1, monthsBackwardCount: 1, startDate: Date()), cellClosure: { date in
        let day = dayFormatter.string(from: date)
        let month = monthFormatter.string(from: date)
        let data = DayCell.ViewModel(day: day, month: month)
        return CollectionCell<DayCell>(data: data, id: day + month)
      }
    )
    let monthes = results.map { $0.monthLayout }
    let layout = CalendarCollectionViewLayout()
    layout.monthLayoutClosure = { index in
      if index < monthes.count {
        return monthes[index]
      }
      return .init(startDayIndex: 0)
    }
    collectionView.collectionViewLayout = layout

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    collectionView.source.sections = results.map { $0.section }
    collectionView.isPagingEnabled = true
    collectionView.reloadData()
  }
}
