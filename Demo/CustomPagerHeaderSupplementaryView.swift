//
//  CustomPagerHeaderSupplementaryView.swift
//  Demo
//
//  Created by Sergei Mikhan on 4/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Sundial
import Astrolabe

class CustomPagerHeaderSupplementaryView<T: CollectionViewCell, M: CollectionViewCell>: PagerHeaderSupplementaryView<T, M> where T: Reusable, T.Data: Titleable, T.Data: Indicatorable {

  let label: UILabel = {
    let label = UILabel()
    label.textColor = .black
    return label
  }()

  override func setup() {
    super.setup()
    contentView.addSubview(label)

    layout?.progress.subscribe(onNext: { [weak self] in
      self?.label.text = "\($0.pages.lowerBound) - \($0.progress)"
    }).disposed(by: disposeBag)
  }

  override open func layoutPagerHeaderContainerView() {
    pagerHeaderContainerView.frame = CGRect(origin: .zero, size: CGSize(width: contentView.bounds.width,
                                                                        height: contentView.bounds.height * 0.5))

    label.frame = CGRect(x: 0.0, y: contentView.bounds.midY,
                         width: contentView.bounds.width,
                         height: contentView.bounds.height * 0.5)
  }
}
