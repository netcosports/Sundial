//
//  CallendarDayFactory.swift
//  Sundial
//
//  Created by Sergei Mikhan on 4/20/20.
//

import Astrolabe

public protocol DateIntervalContainer {
  var interval: DateInterval { get }
}

extension DateIntervalContainer {

  func offsets(from date: Date, timestampInterval: Double) -> (start: CalendarDayOffset, end: CalendarDayOffset) {
    return (
      interval.start.offset(from: date, timestampInterval: timestampInterval),
      interval.end.offset(from: date, timestampInterval: timestampInterval)
    )
  }
}

public extension Date {

  func offset(from date: Date, timestampInterval: Double) -> CalendarDayOffset {
    let offset = self.timeIntervalSince(date)
    let timestamps = Int(offset / timestampInterval)
    let relative = CGFloat((offset - Double(timestamps) * timestampInterval) / timestampInterval)
    return (timestamps, relative)
  }
}

public struct CallendarDayFactoryInput<Data: DateIntervalContainer> {
  let startDate: Date
  let events: [Data]
  let overlays: [Data]

  public init(startDate: Date, events: [Data], overlays: [Data]) {
    self.startDate = startDate
    self.events = events
    self.overlays = overlays
  }
}

public enum SupplementaryRequest {
  case timestamp(Date)
  case nowIndicator(CalendarDayOffset)
  case customOverlay(start: CalendarDayOffset, end: CalendarDayOffset)
}

public func callendarDayFactory<T: DateIntervalContainer>(
  input: CallendarDayFactoryInput<T>,
  supplementaryClosure: (SupplementaryRequest) -> (Cellable?),
  cellClosure: (T, CalendarDayOffset, CalendarDayOffset) -> (Cellable & CalendarDayIntervalContainer),
  sectionClosure: (([Cellable], [Cellable]) -> (Sectionable))? = nil
) -> [Sectionable] {
  let startOfDay = input.startDate.startOfDay
  var supplementaries: [Cellable] = []
  let timestampInterval = 60.0 * 60.0
  (0...24).forEach { index in
    let timestampDate = startOfDay.addingTimeInterval(TimeInterval(index) * timestampInterval)
    if let supplementary = supplementaryClosure(.timestamp(timestampDate)) {
      supplementaries.append(supplementary)
    }
  }

  if startOfDay.isToday {
    if let supplementary = supplementaryClosure(.nowIndicator(Date().offset(from: startOfDay, timestampInterval: timestampInterval))) {
      supplementaries.append(supplementary)
    }
  }

  input.overlays.forEach { interval in
    let offsets = interval.offsets(from: startOfDay, timestampInterval: timestampInterval)
    if let customOverlay = supplementaryClosure(.customOverlay(start: offsets.start, end: offsets.end)) {
      supplementaries.append(customOverlay)
    }
  }

  let cells: [Cellable] = input.events.map { event in
    let offsets = event.offsets(from: startOfDay, timestampInterval: timestampInterval)
    return cellClosure(event, offsets.start, offsets.end)
  }

  let section: Sectionable
  if let sectionClosure = sectionClosure {
    section = sectionClosure(supplementaries, cells)
  } else {
    section = MultipleSupplementariesSection(supplementaries: supplementaries, cells: cells)
  }
  return [section]
}
