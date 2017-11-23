//
//  TitleCollectionViewCell.swift
//  PSGOneApp
//
//  Created by Eugen Filipkov on 4/17/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import Astrolabe

open class TitleCollectionViewCell: CollectionViewCell, Reusable {

  open let titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.textAlignment = .center
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
    titleLabel.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  public struct TitleViewModel: Titleable, Indicatorable {

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
         fadeTextFont: UIFont? = nil) {

      self.title = title
      self.textColor = textColor
      self.fadeTextColor = fadeTextColor
      self.indicatorColor = indicatorColor
      self.textFont = textFont
      self.fadeTextFont = fadeTextFont ?? textFont
    }
  }

  public typealias Data = TitleViewModel
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
