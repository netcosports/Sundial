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
    title.textColor = .black
    title.textAlignment = .center
    title.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
    return title
  }()

  open override func setup() {
    super.setup()
    title.backgroundColor = .green
    contentView.addSubview(title)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    title.center = CGPoint(x: contentView.bounds.midX,
                           y: contentView.bounds.midY)
    title.bounds = contentView.bounds
  }

  open func setup(with data: String) {
    title.text = data
  }

  public static func size(for data: String, containerSize: CGSize) -> CGSize {
    //return CGSize(width: containerSize.width, height: containerSize.width)
    return CGSize(width: containerSize.width * 0.35, height: 320.0)
  }

  public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    if let autoAligned = layoutAttributes as? AutoAlignedCollectionViewLayoutAttributes {
      print("index: \(indexPath?.item ?? 0); \(autoAligned.progress)")

      let scale: CGFloat = 0.65 + 0.35 * autoAligned.progress
      title.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    super.apply(layoutAttributes)
  }
}

let containerView = CollectionView<CollectionViewSource>()
containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 420.0))

let layout = AutoAlignedCollectionViewLayout(settings: .init(alignment: .start, inset: 0.0, fillWithSideInsets: true))
layout.scrollDirection = .horizontal
layout.minimumInteritemSpacing = 50.0
layout.minimumLineSpacing = 50.0

containerView.collectionViewLayout = layout
containerView.backgroundColor = .red
containerView.decelerationRate = .fast
var cells: [Cellable] = (0...50).map { "Item \($0)" }.map { CollectionCell<TestCell>(data: $0) }
containerView.source.sections = [Section(cells: []), Section(cells: cells), Section(cells: []),]
containerView.reloadData()

PlaygroundPage.current.liveView = containerView
