//
//  ShadowCollectionViewLayout.swift
//
//  Created by Eugen Filipkov on 2/10/20.
//

import Astrolabe

public struct ShadowLayoutOptions {
	public struct ShadowOptions: Equatable {
		let backgroundColor: UIColor
		let shadowColor: UIColor
		let shadowRadius: CGFloat
		let shadowPath: CGPath?
		let shadowOpacity: Float
		let shadowOffset: CGSize

		// default values is ~ sketch shadow options
		public init(backgroundColor: UIColor = .white, shadowColor: UIColor = UIColor.black, shadowRadius: CGFloat = 4 * 0.5,
								shadowPath: CGPath? = nil, shadowOpacity: Float = 0.15, shadowOffset: CGSize = CGSize(width: 0, height: 2)) {
			self.backgroundColor = backgroundColor
			self.shadowColor = shadowColor
			self.shadowRadius = shadowRadius
			self.shadowPath = shadowPath
			self.shadowOpacity = shadowOpacity
			self.shadowOffset = shadowOffset
		}
	}
  public let section: Int
	public let shadowOptions: ShadowOptions?

  public init(section: Int, isNeedShowShadow: Bool = false, insets: UIEdgeInsets = .zero, shadowOptions: ShadowOptions? = .init()) {
    self.section = section
		self.shadowOptions = shadowOptions
  }
}

open class ShadowDecorationViewLayoutAttributes: UICollectionViewLayoutAttributes {
	public var shadowOptions: ShadowLayoutOptions.ShadowOptions?

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? ShadowDecorationViewLayoutAttributes else {
      return copy
    }
    typedCopy.shadowOptions = shadowOptions
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    guard let typedObject = object as? ShadowDecorationViewLayoutAttributes else {
      return false
    }

    if typedObject.shadowOptions == nil && self.shadowOptions == nil {
      return true
    }

    return typedObject.shadowOptions == self.shadowOptions
  }
}

open class ShadowDecorationView: UICollectionReusableView, Decorationable {
	public static var zIndex: Int {
    return Int.max
  }
	public static var kind: String {
    return "shadow_decoration_view"
  }

	required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

	public override init(frame: CGRect) {
		super.init(frame: frame)
	}

	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)
		if let layoutAttributes = layoutAttributes as? ShadowDecorationViewLayoutAttributes,
			let options = layoutAttributes.shadowOptions {
			backgroundColor = options.backgroundColor
			layer.shadowColor = options.shadowColor.cgColor
			layer.shadowRadius = options.shadowRadius
			layer.shadowPath = options.shadowPath
			layer.shadowOpacity = options.shadowOpacity
			layer.shadowOffset = options.shadowOffset
		}
	}
}

// swiftlint:disable line_length
open class ShadowCollectionViewLayout<DecorationView: UICollectionReusableView>: EmptyViewCollectionViewLayout where DecorationView: Decorationable {
	public var options: [ShadowLayoutOptions]? {
		didSet {
			invalidateLayout()
		}
	}

  public init(options: [ShadowLayoutOptions]? = nil) {
    self.options = options
    super.init()
  }

	public override init() {
		super.init()
	}

	required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func prepare() {
    super.prepare()

    register(DecorationView.self,
             forDecorationViewOfKind: DecorationView.kind)
  }

  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let attributes = super.layoutAttributesForElements(in: rect)
    var allAttributes = [UICollectionViewLayoutAttributes]()
    if let attributes = attributes,
      let options = options {
      let cellsAttributes = attributes.filter { attr in
        attr.representedElementCategory == .cell &&
          options.contains(where: { $0.section == attr.indexPath.section })
      }
      let sections = Dictionary(grouping: cellsAttributes, by: { $0.indexPath.section })
      sections.forEach {
        if let attribute = $0.value.first,
          let cellWidth = $0.value.filter({ $0.frame.width != collectionView?.frame.width }).compactMap({ $0.frame.width }).max() {
          let height = $0.value.reduce(0) { $0 + $1.frame.height }
          let decorationAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: DecorationView.kind,
          with: attribute.indexPath)
          decorationAttributes.frame = CGRect(x: attribute.frame.origin.x,
                                              y: attribute.frame.origin.y,
                                              width: cellWidth,
                                              height: height)
          decorationAttributes.zIndex = attribute.zIndex - 1
          allAttributes.append(decorationAttributes)
        }
      }
      allAttributes.append(contentsOf: attributes)
    }

    return allAttributes
  }
}
