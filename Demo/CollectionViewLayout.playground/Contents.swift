//: A UIKit based Playground for presenting user interface
  

import UIKit
import Astrolabe
import Sundial
import SnapKit

import PlaygroundSupport


open class GenericCollectionViewLayout<DecorationView: CollectionViewCell & DecorationViewPageable>: PlainCollectionViewLayout {

  public typealias ViewModel = DecorationView.TitleCell.Data
  public typealias PagerClosure = ()->[ViewModel]

  open var pager: PagerClosure?

  open var decorationFrame: CGRect {
    guard let collectionView = collectionView else { return .zero }

    let topOffset: CGFloat
    switch settings.alignment {
    case .top:
      topOffset = 0.0
    case .topOffset(let variable):
      topOffset = variable.value
    }

    return CGRect(x: collectionView.contentOffset.x,
                  y: topOffset,
                  width: collectionView.frame.width,
                  height: settings.stripHeight)
  }

  // MARK: - Init

  public required init(hostPagerSource: Source, settings: Sundial.Settings? = nil , pager: PagerClosure?) {
    self.pager = pager
    super.init(hostPagerSource: hostPagerSource, settings: settings)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Override

  open override func prepare() {
    register(DecorationView.self, forDecorationViewOfKind: DecorationViewId)
    super.prepare()
  }

//  open override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
//    print("TEST \(context.invalidateEverything), \(context.invalidatedItemIndexPaths), \(context.invalidatedDecorationIndexPaths)")
//    super.invalidateLayout(with: context)
//  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let sourceAttributes = super.layoutAttributesForElements(in: rect) ?? []
    var attributes = sourceAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

    addDecorationAttributes(to: &attributes)
    //addJumpAttributes(to: &attributes)
    return attributes
  }

  open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attributes = layoutAttributesForElements(in: .infinite) else { return nil }

    for attribute in attributes {
      if attribute.representedElementCategory == .cell && attribute.indexPath == indexPath {
        return attribute
      }
    }
    return nil
  }

  open override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard elementKind == DecorationViewId, indexPath == IndexPath(item: 0, section: 0) else { return nil }
    return decorationAttributes(with: pager?())
  }

  // MARK: - Open

  open func adjustItem(frame: CGRect) -> CGRect {
    let bottom = settings.bottomStripSpacing
    let height = settings.stripHeight

    return CGRect(x: frame.origin.x,
                  y: height + bottom,
                  width: frame.width,
                  height: frame.height - height - bottom)
  }

  open func decorationAttributes(with titles: [ViewModel]?) -> DecorationView.Attributes? {
    guard let titles = titles, titles.count > 0 else {
      return nil
    }

    let settings = self.settings
    let validPagesRange = 0...(titles.count - settings.pagesOnScreen)
    let decorationIndexPath = IndexPath(item: 0, section: 0)
    let decorationAttributes = DecorationView.Attributes(forDecorationViewOfKind: DecorationViewId, with: decorationIndexPath)
    decorationAttributes.zIndex = 1024
    decorationAttributes.settings = settings
    decorationAttributes.titles = titles
    decorationAttributes.hostPagerSource = hostPagerSource
    decorationAttributes.selectionClosure = { [weak self] _ in
      guard let `self` = self else { return }

      //let item = $0.clamp(to: validPagesRange)
      //self.select(item: item, jumpingPolicy: settings.jumpingPolicy)
    }
    decorationAttributes.frame = decorationFrame

    return decorationAttributes
  }

  // MARK: - Internal

  func addDecorationAttributes(to attributes: inout [UICollectionViewLayoutAttributes]) {
    guard attributes.count > 0 else { return }
    guard let decorationAttributes = self.decorationAttributes(with: pager?()) else {
      return
    }

    attributes.forEach {
      $0.frame = adjustItem(frame: $0.frame)
    }
    attributes.append(decorationAttributes)
    print("TEST ADD ATTRIBUTES \(decorationAttributes)")
  }

}
public typealias CollectionViewLayout = GenericCollectionViewLayout<DecorationView>


class ViewControllerInner: UIViewController {

  let controller1 = UIViewController()
  let controller2 = UIViewController()
  let controller3 = UIViewController()
  let controller4 = UIViewController()
  let controller5 = UIViewController()

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

  let collectionView = CollectionView<CollectionViewPagerSource>()

  typealias Layout = CollectionViewLayout

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.source.hostViewController = self
    collectionView.source.pager = self

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
                            jumpingPolicy: .disabled)

    collectionView.collectionViewLayout = Layout(hostPagerSource: collectionView.source, settings: settings) { [weak self] in
      return self?.titles ?? []
    }

    view.addSubview(collectionView)
    collectionView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }

    controller1.view.backgroundColor = .blue
    controller2.view.backgroundColor = .black
    controller3.view.backgroundColor = .green
    controller4.view.backgroundColor = .gray
    controller5.view.backgroundColor = .orange

    collectionView.source.reloadData()

    let button = UIButton()
    button.backgroundColor = .magenta
    button.addTarget(self, action: #selector(click), for: UIControl.Event.touchUpInside)
    controller2.view.addSubview(button)
    button.snp.remakeConstraints {
      $0.height.width.equalTo(120)
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(60)
    }
  }

  @objc func click() {
    self.count = 1
    self.collectionView.source.reloadData()
  }
}

extension ViewControllerInner: CollectionViewPager {

  var pages: [Page] {
    return Array([
      Page(controller: controller1, id: "Title 1"),
      Page(controller: controller2, id: "Title 2"),
      Page(controller: controller3, id: "Title 3"),
      Page(controller: controller4, id: "Title 4"),
      Page(controller: controller5, id: "Title 5")
    ].prefix(count))
  }
}

extension ViewControllerInner {

  var titles: [TitleCollectionViewCell.TitleViewModel] {
    if inverted {
      return Array([
        TitleCollectionViewCell.TitleViewModel(title: "Mid Blue", id: "Inverted Mid Blue", indicatorColor: .magenta),
        TitleCollectionViewCell.TitleViewModel(title: "Super Long Black", indicatorColor: .black),
        TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
        TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
        TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
      ].prefix(count))
    } else {
      return Array([
        TitleCollectionViewCell.TitleViewModel(title: "Mid Blue", indicatorColor: .blue),
        TitleCollectionViewCell.TitleViewModel(title: "Super Long Black", indicatorColor: .black),
        TitleCollectionViewCell.TitleViewModel(title: "Green", indicatorColor: .green),
        TitleCollectionViewCell.TitleViewModel(title: "Gray", indicatorColor: .gray),
        TitleCollectionViewCell.TitleViewModel(title: "Orange", indicatorColor: .orange)
      ].prefix(count))
    }
  }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = ViewControllerInner(Anchor.content(Distribution.equalSpacing))
