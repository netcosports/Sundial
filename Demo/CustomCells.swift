//
//  CustomCells.swift
//  Sundial_Example
//
//  Created by Sergei Mikhan on 11/18/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial

extension UIColor {

  func blended(with color: UIColor, progress: CGFloat) -> UIColor {
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

open class CustomTitleCollectionViewCell: CollectionViewCell, Reusable {

  open let titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.textAlignment = .center
    return label
  }()

  open let liveMarkerLabel: UILabel = {
    let label = UILabel()
    label.text = "12"
    label.textColor = .white
    label.textAlignment = .center
    label.backgroundColor = .red
    label.font = UIFont.systemFont(ofSize: 8)
    label.layer.cornerRadius = 20 / 2
    label.clipsToBounds = true
    return label
  }()

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    guard let attributes = layoutAttributes as? TitleCollectionViewLayoutAttributes else {
      return
    }

    fade = attributes.fade
  }

  open override func setup() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(liveMarkerLabel)

    titleLabel.snp.remakeConstraints { make in
      make.center.equalToSuperview()
    }

    liveMarkerLabel.snp.remakeConstraints { make in
      make.centerX.equalTo(titleLabel.snp.trailing)
      make.centerY.equalTo(titleLabel.snp.top)
      make.height.width.equalTo(20)
    }
  }

  public struct CustomTitleViewModel: Titleable, Indicatorable {

    public let title: String
    public let textColor: UIColor
    public let fadeTextColor: UIColor
    public let indicatorColor: UIColor
    public let textFont: UIFont
    public let fadeTextFont: UIFont

    public init(title: String,
                textColor: UIColor = .black,
                fadeTextColor: UIColor = .green,
                indicatorColor: UIColor = .red,
                textFont: UIFont = UIFont.systemFont(ofSize: 15),
                fadeTextFont: UIFont = UIFont.systemFont(ofSize: 15)) {

      self.title = title
      self.textColor = textColor
      self.fadeTextColor = fadeTextColor
      self.indicatorColor = indicatorColor
      self.textFont = textFont
      self.fadeTextFont = fadeTextFont
    }
  }

  public typealias Data = CustomTitleViewModel
  var data: Data? {
    didSet {
      updateFade()
    }
  }

  var fade: CGFloat = 0 {
    didSet {
      updateFade()
    }
  }

  open func updateFade() {
    let textColor: UIColor?
    let font: UIFont?
    if let data = data {
      textColor = data.textColor.blended(with: data.fadeTextColor, progress: (1 - fade))
      font = (fade == 0.0) ? data.fadeTextFont : data.textFont
      liveMarkerLabel.backgroundColor = data.indicatorColor
    } else {
      textColor = nil
      font = UIFont.systemFont(ofSize: 15)
    }
    titleLabel.textColor = textColor
    titleLabel.font = font
  }

  open func setup(with data: Data) {
    titleLabel.text = data.title
    self.data = data
  }

  open static func size(for data: Data, containerSize: CGSize) -> CGSize {
    let width = data.title.width(with: data.textFont) + 1
    return CGSize(width: ceil(width), height: containerSize.height)
  }
}

open class CustomMarkerDecorationView: CollectionViewCell {

  open let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "marker"
    label.textColor = .white
    label.textAlignment = .center
    return label
  }()

  open override func setup() {
    super.setup()

    contentView.addSubview(titleLabel)
  }

  open override func updateConstraints() {
    titleLabel.snp.remakeConstraints {
      $0.bottom.leading.trailing.equalToSuperview()
    }

    super.updateConstraints()
  }

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    if let layoutAttributes = layoutAttributes as? MarkerDecorationAttributes<CustomTitleCollectionViewCell.CustomTitleViewModel, CustomMarkerDecorationView> {
      titleLabel.textColor = layoutAttributes.color
    }
  }
}
