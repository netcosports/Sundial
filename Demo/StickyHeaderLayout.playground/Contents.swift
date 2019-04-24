//: A UIKit based Playground for presenting user interface
  
import UIKit
import Sundial
import Astrolabe
import SnapKit
import PlaygroundSupport

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
    return CGSize(width: containerSize.width, height: 76)
  }
}

public  class HeaderTestCell: CollectionViewCell, Reusable {

  let title: UILabel = {
    let title = UILabel()
    title.textColor = .white
    title.textAlignment = .center
    return title
  }()

  open override func setup() {
    super.setup()
    contentView.backgroundColor = .orange
    contentView.addSubview(title)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    title.frame = contentView.bounds
    title.text = "HEADER height is \(Int(self.frame.height))"
  }

  public static func size(for data: Void, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 276)
  }
}

let containerView = CollectionView<CollectionViewSource>()
let settings =  StickyHeaderCollectionViewLayout.Settings(
  sticky: true,
  minHeight: 80.0
)
containerView.collectionViewLayout = StickyHeaderCollectionViewLayout(settings: settings)
containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 620.0))
containerView.backgroundColor = .red
var cells: [Cellable] = (1...100).map { "Item \($0)" }.map { CollectionCell<TestCell>(data: $0) }
cells.insert(CollectionCell<HeaderTestCell>(data: ()), at: 0)
containerView.source.sections = [Section(cells: cells)]
containerView.reloadData()

PlaygroundPage.current.liveView = containerView
