//
//  CallendarFactory.swift
//  Sundial
//
//  Created by Sergei Mikhan on 3/19/20.
//

import Astrolabe

public typealias CellClosure = (Date) -> Cellable
public typealias SectionClosure = (Date, [Cellable]) -> Sectionable
public typealias CalendarFactoryResult = (monthLayout: CalendarCollectionViewLayout.MonthLayout, section: Sectionable)

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

public func callendarFactory(input: CallendarFactoryInput,
                             cellClosure: CellClosure,
                             sectionClosure: SectionClosure? = nil) -> [CalendarFactoryResult] {
  var startOfMonth = input.startDate.monthesBefore(input.monthsBackwardCount).startOfMonth
  var endOfMonth = startOfMonth.endOfMonth
  var date = startOfMonth
  var results: [CalendarFactoryResult] = []
  (0..<(input.monthsBackwardCount + input.monthsForwardCount + 1)).forEach { _ in
    var cells: [Cellable] = []

    repeat {
      cells.append(cellClosure(date))
      date = date.nextDay
    } while date < endOfMonth

    let section: Sectionable
    if let sectionClosure = sectionClosure {
      section = sectionClosure(startOfMonth, cells)
    } else {
      section = Section(cells: cells)
    }
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

  var startOfMonth: Date {
    Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
  }

  var endOfMonth: Date {
    Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
  }

  var startOfDay: Date {
    Calendar.current.startOfDay(for: self)
  }

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
