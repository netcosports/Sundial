//: A UIKit based Playground for presenting user interface

import UIKit
import Sundial
import Astrolabe
import SnapKit
import PlaygroundSupport

import RxSwift
import RxCocoa

class TestCell: CollectionViewCell, Reusable, Eventable {

  private let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    return title
  }()

  override func setup() {
    super.setup()
    self.backgroundColor = .green
    contentView.addSubview(title)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = contentView.bounds
  }

  func setup(with data: String) {
    title.text = data
  }

  typealias Event = String
  var data: String?
  let eventSubject = PublishSubject<Event>()

  static func size(for data: String, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 120)
  }
}

class HeaderTestCell: CollectionViewCell, Reusable, Eventable {

  typealias Event = String
  var data: String?
  let eventSubject = PublishSubject<Event>()

  private let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    return title
  }()

  override func setup() {
    super.setup()
    contentView.backgroundColor = .orange
    contentView.addSubview(title)
  }

  func setup(with data: String) {
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = contentView.bounds
    title.text = "height is \(Int(self.frame.height))"
  }

  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let stickyLayoutAttributes = layoutAttributes as? StickyHeaderCollectionViewLayoutAttributes {
      print("progress  is \(stickyLayoutAttributes.progress)")
    }
  }

  static func size(for data: String, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 276)
  }
}

let containerView = CollectionView<CollectionViewSource<String, String>>()
let settings =  StickyHeaderCollectionViewLayout.Settings(
  sticky: true,
  minHeight: 80.0,
  alignToEdges: true
)
containerView.collectionViewLayout = StickyHeaderCollectionViewLayout(settings: settings)
containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 620.0))
containerView.backgroundColor = .red
var cells: [Cell<String>] = (1...100).map { "Item hello \($0)" }.map { Cell(cell: TestCell.self, state: $0) }
cells.insert(Cell(cell: HeaderTestCell.self, state: "header"), at: 0)
let sections = [Section<String, String>(cells: cells, state: "section", supplementaries: [])]
containerView.source.apply(
  sections: sections
)

PlaygroundPage.current.liveView = containerView
