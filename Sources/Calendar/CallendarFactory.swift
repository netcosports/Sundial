//
//  CallendarFactory.swift
//  Sundial
//
//  Created by Sergei Mikhan on 3/19/20.
//

import Foundation
import Astrolabe

public typealias CellClosure<CellState: Hashable> = (Date) -> Cell<CellState>
public typealias SectionClosure<SectionState: Hashable, CellState: Hashable> = (Date, [Cell<CellState>]) -> Section<SectionState, CellState>
public typealias CalendarFactoryResult<SectionState: Hashable, CellState: Hashable> = (
  monthLayout: CalendarCollectionViewLayout.MonthLayout, section: Section<SectionState, CellState>
)

public struct CallendarFactoryInput {
  let monthsForwardCount: Int
  let monthsBackwardCount: Int
  let startDate: Date
  let firstWeekday: Int // Sun 1, Mon 2, Tue 3, Wed 4, Fri 5, Sat 6

  public init(monthsForwardCount: Int,
              monthsBackwardCount: Int,
              startDate: Date,
              firstWeekday: Int = Calendar.current.firstWeekday) {
    self.monthsForwardCount = monthsForwardCount
    self.monthsBackwardCount = monthsBackwardCount
    self.startDate = startDate
    self.firstWeekday = firstWeekday
  }
}

@available(iOS 10.0, *)
public func callendarFactory<SectionState: Hashable, CellState: Hashable>(
  input: CallendarFactoryInput,
  cellClosure: CellClosure<CellState>,
  sectionClosure: SectionClosure<SectionState, CellState>
) -> [CalendarFactoryResult<SectionState, CellState>] {
  var startOfMonth = input.startDate.monthesBefore(input.monthsBackwardCount).startOfMonth
  var endOfMonth = startOfMonth.endOfMonth
  var date = startOfMonth
  var results: [CalendarFactoryResult<SectionState, CellState>] = []
  (0..<(input.monthsBackwardCount + input.monthsForwardCount + 1)).forEach { _ in
    var cells: [Cell<CellState>] = []

    repeat {
      cells.append(cellClosure(date))
      date = date.nextDay
    } while date < endOfMonth

    let section = sectionClosure(startOfMonth, cells)
    var startDayIndex = startOfMonth.weekDay - input.firstWeekday
    if startDayIndex < 0 {
      startDayIndex = 7 + startDayIndex
    }
    results.append((monthLayout: .init(startDayIndex: startDayIndex), section: section))
    startOfMonth = startOfMonth.nextMonth.startOfMonth
    endOfMonth = startOfMonth.endOfMonth
    date = startOfMonth
  }
  return results
}

extension Date {

	@available(iOS 10.0, *)
	var startOfMonth: Date {
    Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
  }

	@available(iOS 10.0, *)
	var endOfMonth: Date {
    Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
  }

  var startOfDay: Date {
    Calendar.current.startOfDay(for: self)
  }

	@available(iOS 10.0, *)
	var endOfDay: Date {
    Calendar.current.dateInterval(of: .day, for: self)?.end ?? self
  }

  func monthesBefore(_ count: Int) -> Date {
    Calendar.current.date(byAdding: .month, value: -count, to: self) ?? self
  }

  var nextMonth: Date {
    Calendar.current.date(byAdding: .month, value: 1, to: self) ?? self
  }

  var nextDay: Date {
    Calendar.current.date(byAdding: .day, value: 1, to: self) ?? self
  }

  var isToday: Bool {
    Calendar.current.isDateInToday(self)
  }

  var weekDay: Int {
    return Calendar.current.dateComponents([.weekday], from: self).weekday ?? 0
  }
}
