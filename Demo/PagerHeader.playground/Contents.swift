//: A UIKit based Playground for presenting user interface

import UIKit
import Astrolabe
import Sundial
import SnapKit

import PlaygroundSupport

class ColoredViewController: UIViewController, ReusedPageData {

  var data: UIColor? {
    didSet {
      view.backgroundColor = data
    }
  }
}


class ViewControllerInner: UIViewController {

  var inverted = false

  let anchor: Anchor
  var count: Int
  let margin: CGFloat

  init(_ anchor: Anchor, count: Int = 5, margin: CGFloat = 80) {
    self.anchor = anchor
    self.count = count
    self.margin = margin
    guard (1 ... 5).contains(count) else { fatalError() }
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  let collectionView = CollectionView<CollectionViewReusedPagerSource>()

  typealias Layout = PagerHeaderCollectionViewLayout

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self

    let margin: CGFloat
    switch anchor {
    case .fillEqual:
      margin = 0.0
    default:
      margin = self.margin
    }

    let settings = Settings(stripHeight: 80.0,
                            markerHeight: 5.5,
                            itemMargin: margin,
                            bottomStripSpacing: 0.0,
                            anchor: anchor,
                            inset: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin),
                            numberOfTitlesWhenHidden: 1)

    collectionView.collectionViewLayout = Layout(hostPagerSource: collectionView.source, settings: settings)

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    let colors: [UIColor] = [
      .blue, .black, .green, .gray, .orange
    ]

    let cells: [Cellable] = colors.map {
      CollectionCell<ReusedPagerCollectionViewCell<ColoredViewController>>(data: $0)
    }

    typealias Supplementary = PagerHeaderSupplementaryView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.Data>>
    let supplementary = CollectionCell<Supplementary>(data: titles, id: "", click: nil, type: .custom(kind: PagerHeaderSupplementaryViewKind), setup: nil)
    let section = MultipleSupplementariesSection(supplementaries: [supplementary], cells: cells)
    collectionView.source.sections = [section]
    collectionView.reloadData()
  }
}

extension ViewControllerInner {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return Array([
      TitleCollectionViewCell.TitleViewModel(title: "Mid Blue", id: "Inverted Mid Blue", indicatorColor: .magenta),
      TitleCollectionViewCell.TitleViewModel(title: "Super Long Black", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
      ].prefix(count))
  }
}

PlaygroundPage.current.liveView = ViewControllerInner(.content(Distribution.center))
