//: A UIKit based Playground for presenting user interface

import UIKit
import Astrolabe
import Sundial
import SnapKit

import RxSwift
import RxCocoa

import PlaygroundSupport

class CollapsingCell: CollectionViewCell, Reusable, Eventable {

  typealias Data = String

  typealias Event = String
  var data: Data?
  let eventSubject = PublishSubject<Event>()

  private let title: UILabel = {
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

  func setup(with data: Data) {

  }

//  public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
//    super.apply(layoutAttributes)
//    if let collapsingHeaderViewAttributes = layoutAttributes as? CollapsingHeaderViewAttributes {
//      print("progress is \(collapsingHeaderViewAttributes.progress)")
//    }
//  }

  public static func size(for data: String, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: 276)
  }
}

class TestCell: CollectionViewCell, Reusable, Eventable {

  typealias Data = String

  typealias Event = String
  var data: Data?
  let eventSubject = PublishSubject<Event>()

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

  func setup(with data: Data) {
    title.text = data
  }

  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: containerSize.width * 0.35)
  }
}

class ColoredViewController: UIViewController, ReusedData, Eventable, CollapsingItem {
  var scrollView: UIScrollView {
    return containerView
  }
  var visible = BehaviorRelay<Bool>(value: false)

  typealias Event = String
  let eventSubject = PublishSubject<Event>()

  var data: UIColor? {
    didSet {
      //containerView.backgroundColor = data
      //print(data)
    }
  }

  let containerView = CollectionView<CollectionViewSource<String, String>>()

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
    containerView.frame = view.bounds

    let cells: [Cell<String>] = (1...50).map { "Item \($0)" }.map {
      Cell(cell: TestCell.self, state: $0, eventsEmmiter: self.eventSubject.asObserver(), clickEvent: "")
    }
    let sections = [
      Section<String, String>(cells: cells, state: "", supplementaries: [])
    ]
    containerView.source.apply(
      sections: sections
    )
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

  let collectionView = CollectionView<CollectionViewReusedPagerSource<String, UIColor>>()

  let action = PublishSubject<Void>()
  let disposeBag = DisposeBag()

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
                            itemMargin: 0.0,
                            backgroundColor: .white,
                            anchor: anchor,
                            inset: UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin),
                            numberOfTitlesWhenHidden: 1,
                            pagerIndependentScrolling: false)

    let layout = PagerHeaderCollectionViewLayout(
      hostPagerSource: collectionView.source,
      settings: settings
    )
    collectionView.collectionViewLayout = layout
    view.addSubview(collectionView)

    let colors: [UIColor] = [
      .blue, .black, .green, .gray, .orange
    ]

    action.subscribe(onNext: { [weak layout] in
      layout?.scrollToTop()
    }).disposed(by: disposeBag)

    let cells: [Cell<UIColor>] = colors.map {
      Cell(cell: ReusedPagerCollectionViewCell<ColoredViewController>.self, state: $0, setup: { [weak layout, weak self] cellView in
        layout?.append(collapsingItems: [cellView.viewController])
      })
    }

    typealias Supplementary = PagerHeaderSupplementaryView<TitleCollectionViewCell, MarkerDecorationView<TitleCollectionViewCell.Data>>
    let supplementaryPager: Cellable = CellContainer<Supplementary>(
      data: titles,
      type: .custom(kind:  PagerHeaderSupplementaryViewKind)
    )
    let supplementaryCollapsing: Cellable = CellContainer<CollapsingCell>(
      data: "collapsing",
      type: .custom(kind:  PagerHeaderCollapsingSupplementaryViewKind)
    )

    let sections = [Section<String, UIColor>(
      cells: cells,
      state: "",
      supplementaries: [supplementaryPager, supplementaryCollapsing]
    )]
    collectionView.source.apply(
      sections: sections
    )
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
  }
}

extension ViewControllerInner {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    return Array([
      TitleCollectionViewCell.TitleViewModel(title: "     1     ", id: "Inverted Mid Blue", indicatorColor: .magenta),
      TitleCollectionViewCell.TitleViewModel(title: "     2     ", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "     3     ", indicatorColor: .green),
      TitleCollectionViewCell.TitleViewModel(title: "     4     ", indicatorColor: .gray),
      TitleCollectionViewCell.TitleViewModel(title: "     5     ", indicatorColor: .orange),

      TitleCollectionViewCell.TitleViewModel(title: "     6     ", indicatorColor: .black),
      TitleCollectionViewCell.TitleViewModel(title: "     7     ", indicatorColor: .green)
    ])
  }
}

PlaygroundPage.current.liveView = ViewControllerInner(.content(Distribution.center))
