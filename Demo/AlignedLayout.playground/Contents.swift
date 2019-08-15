//: A UIKit based Playground for presenting user interface

import UIKit
import Sundial
import Astrolabe
import SnapKit
import PlaygroundSupport

//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////

public class TestCell: CollectionViewCell, Reusable {

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    return title
  }()

  open override func setup() {
    super.setup()
    self.backgroundColor = .green
    contentView.addSubview(title)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = contentView.bounds
  }

  open func setup(with data: String) {
    title.text = data
  }

  public static func size(for data: String, containerSize: CGSize) -> CGSize {
    //return CGSize(width: containerSize.width, height: containerSize.width)
    return CGSize(width: containerSize.width * 0.35, height: containerSize.width)
  }
}

let containerView = CollectionView<CollectionViewSource>()
containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 640.0))

let layout = AutoAlignedCollectionViewLayout(settings: .init(alignment: .end, inset: 0.0, target: .factor(0.0)))
layout.scrollDirection = .horizontal
layout.minimumInteritemSpacing = 30.0
layout.minimumLineSpacing = 30.0

containerView.collectionViewLayout = layout
containerView.backgroundColor = .red
containerView.decelerationRate = .fast
var cells: [Cellable] = (1...50).map { "Item \($0)" }.map { CollectionCell<TestCell>(data: $0) }
containerView.source.sections = [Section(cells: cells)]
containerView.reloadData()

PlaygroundPage.current.liveView = containerView
