//: A UIKit based Playground for presenting user interface

import UIKit
import Astrolabe
import Sundial
import SnapKit

import RxSwift
import RxCocoa

import PlaygroundSupport

public  class CollapsingCell: CollectionViewCell, Reusable {

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

  public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let collapsingHeaderViewAttributes = layoutAttributes as? CollapsingHeaderViewAttributes {
      print("progress is \(collapsingHeaderViewAttributes.progress)")
    }
  }

  public static func size(for data: Void, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 276)
  }
}

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
    return CGSize(width: containerSize.width, height: containerSize.width * 0.35)
  }
}

class ColoredViewController: UIViewController, ReusedPageData, CollapsingItem {

  var scrollView: UIScrollView {
    return containerView
  }
  var visible = BehaviorRelay<Bool>(value: false)

  var data: UIColor? {
    didSet {
      view.backgroundColor = data
    }
  }

  let containerView = CollectionView<CollectionViewSource>()

  override func viewDidLoad() {
    super.viewDidLoad()

    containerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 320.0, height: 640.0))

    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumInteritemSpacing = 30.0
    layout.minimumLineSpacing = 30.0

    containerView.collectionViewLayout = layout
    containerView.backgroundColor = .red
    containerView.decelerationRate = .fast

    view.addSubview(containerView)

    var cells: [Cellable] = (1...50).map { "Item \($0)" }.map { CollectionCell<TestCell>(data: $0) }
    containerView.source.sections = [Section(cells: []), Section(cells: cells), Section(cells: []),]
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerView.frame = view.bounds
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    visible.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    visible.accept(false)
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
                            backgroundColor: .white,
                            anchor: anchor,
                            inset: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin),
                            numberOfTitlesWhenHidden: 1,
                            pagerIndependentScrolling: true)

    let layout = Layout(hostPagerSource: collectionView.source, settings: settings)
    collectionView.collectionViewLayout = layout

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    let colors: [UIColor] = [
      .blue, .black, .green, .gray, .orange
    ]

    let cells: [Cellable] = colors.map {
      CollectionCell<ReusedPagerCollectionViewCell<ColoredViewController>>(data: $0, setup: { [weak layout] cellView in
        layout?.append(collapsingItems: [cellView.viewController])
      })
    }

    typealias Supplementary = PagerHeaderSupplementaryView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.Data>>
    let supplementaryPager = CollectionCell<Supplementary>(data: titles, id: "", click: nil,
                                                           type: .custom(kind:  PagerHeaderSupplementaryViewKind), setup: nil)
    let supplementaryCollapsing = CollectionCell<CollapsingCell>(data: (), id: "", click: nil,
                                                                 type: .custom(kind:  PagerHeaderCollapsingSupplementaryViewKind), setup: nil)
    let section = MultipleSupplementariesSection(supplementaries: [supplementaryPager, supplementaryCollapsing], cells: cells)
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
