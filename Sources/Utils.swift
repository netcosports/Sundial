//
//  Utils.swift
//  Sundial
//
//  Created by Sergei Mikhan on 10/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit

func log(_ value: Any..., functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
  let url = URL(fileURLWithPath: fileName)
  let loggedValue = value.count == 0
    ? ""
    : value.reduce("") { "\($0) \(String(reflecting: $1))" }
  print("\(functionName)\(loggedValue) in \(url.lastPathComponent) at line \(lineNumber)")
}

extension UIColor {

  public func blended(with color: UIColor, progress: CGFloat) -> UIColor {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    var red2: CGFloat = 0
    var green2: CGFloat = 0
    var blue2: CGFloat = 0
    var alpha2: CGFloat = 0
    color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

    let part = (1 - progress)
    return UIColor(red: red * part + red2 * progress,
                   green: green * part + green2 * progress,
                   blue: blue * part + blue2 * progress,
                   alpha: alpha * part + alpha2 * progress)
  }
}

extension Array {

  subscript(safe index: Index) -> Element? {
    get { return indices ~= index ? self[index] : nil }
    set {
      guard indices ~= index else { return }
      guard let newValue = newValue else { return }
      remove(at: index)
      insert(newValue, at: index)
    }
  }

  var last: Element? {
    get { return self[safe: self.index(before: endIndex)] }
    set { self[safe: self.index(before: endIndex)] = newValue }
  }
}

extension String {

  func width(with font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect,
                                        options: [.usesFontLeading, .usesLineFragmentOrigin],
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil)

    return boundingBox.width
  }

  func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect,
                                        options: [.usesFontLeading, .usesLineFragmentOrigin],
                                        attributes: [NSAttributedString.Key.font: font],
                                        context: nil)

    return boundingBox.height
  }
}

extension UIEdgeInsets {

  var inverted: UIEdgeInsets {
    return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
  }

  func inset(rect: CGRect) -> CGRect {
    return rect.inset(by: self)
  }

  func inset(size: CGSize) -> CGSize {
    return CGRect(origin: .zero, size: size).inset(by: self).size
  }
}

extension CGRect {

  func linearInterpolation(with rect: CGRect, value: CGFloat) -> CGRect {
    let vec = CGRect(x: rect.origin.x - origin.x,
                     y: rect.origin.y - origin.y,
                     width: rect.size.width - size.width,
                     height: rect.size.height - size.height)
    return CGRect(x: origin.x + vec.origin.x * value,
                  y: origin.y + vec.origin.y * value,
                  width: size.width + vec.size.width * value,
                  height: size.height + vec.size.height * value)
  }
}

extension Int {

  func clamp(to range: CountableClosedRange<Int>) -> Int {
    if range ~= self {
      return self
    }
    return Swift.min(Swift.max(range.lowerBound, self), range.upperBound)
  }
}
