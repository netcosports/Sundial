//: A UIKit based Playground for presenting user interface

import UIKit
import Sundial
import Astrolabe
import SnapKit
import PlaygroundSupport

import RxSwift
import RxCocoa

//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////

class TestCell: CollectionViewCell, Reusable, Eventable {

  typealias Data = String

  typealias Event = String
  var data: Data?
  let eventSubject = PublishSubject<Event>()

  private let title: UILabel = {
    let title = UILabel()
    title.textColor = .black
    title.textAlignment = .center
    title.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
    return title
  }()

  override func setup() {
    super.setup()
    title.backgroundColor = .green
    contentView.addSubview(title)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    title.center = CGPoint(x: contentView.bounds.midX,
                           y: contentView.bounds.midY)
    title.bounds = contentView.bounds
  }

  func setup(with data: Data) {
    title.text = data
  }

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    //return CGSize(width: containerSize.width, height: containerSize.width)
    return CGSize(width: containerSize.width * 0.35, height: 320.0)
  }

  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    if let autoAligned = layoutAttributes as? AutoAlignedCollectionViewLayoutAttributes {
      print("index: \(indexPath?.item ?? 0); \(autoAligned.progress)")

      let scale: CGFloat = 0.65 + 0.35 * autoAligned.progress
      title.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    super.apply(layoutAttributes)
  }
}

let containerView = CollectionView<CollectionViewSource<String, String>>()
containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 420.0))

let layout = AutoAlignedCollectionViewLayout(settings: .init(alignment: .start, inset: 0.0, fillWithSideInsets: true))
layout.scrollDirection = .horizontal
layout.minimumInteritemSpacing = 50.0
layout.minimumLineSpacing = 50.0

containerView.collectionViewLayout = layout
containerView.backgroundColor = .red
containerView.decelerationRate = .fast
var cells: [Cell<String>] = (0...50).map { "Item \($0)" }.map { Cell(cell: TestCell.self, state: $0) }
let sections = [
  Section<String, String>(cells: cells, state: "", supplementaries: [])
]
containerView.source.apply(
  sections: sections
)

PlaygroundPage.current.liveView = containerView
