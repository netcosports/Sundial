//
//  CustomDecorationView.swift
//  Demo
//
//  Created by Timur Bernikowich on 1/29/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Astrolabe
import Sundial

class CustomDecorationView<TitleCell: CollectionViewCell, MarkerCell: CollectionViewCell>: GenericDecorationView<TitleCell, MarkerCell, DecorationViewAttributes<TitleCell.Data>>
where TitleCell: Reusable, TitleCell.Data: ViewModelable {

  let decorationLabel = UILabel()

  override func setup() {
    super.setup()

    decorationLabel.backgroundColor = .yellow
    decorationLabel.textColor = .black
    decorationLabel.text = "decoration"
    contentView.addSubview(decorationLabel)
    decorationLabel.translatesAutoresizingMaskIntoConstraints = false

    contentView.removeConstraints(contentView.constraints)
    let views = ["container": decorationContainerView, "decoration": decorationLabel]

    var constraints: [NSLayoutConstraint] = []
    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[container]|",
                                                                  metrics: nil, views: views))
    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[decoration]|",
                                                                  metrics: nil, views: views))
    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[container][decoration(==20)]|",
                                                                  metrics: nil, views: views))
    contentView.addConstraints(constraints)
  }
}
